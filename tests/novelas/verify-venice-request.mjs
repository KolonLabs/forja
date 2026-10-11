/**
 * Node 22+, Python 3.10+ con PyYAML. Solo HTTP simulado, sin auth.json/OpenCode.
 * PowerShell, desde el workspace (instalacion temporal, nunca en el proyecto):
 * $parent = 'C:/Users/migue/AppData/Local/Temp/opencode'
 * if (-not (Test-Path -LiteralPath $parent -PathType Container)) { throw 'Falta temporal' }
 * $deps = Join-Path $parent ('venice-contract-' + [guid]::NewGuid().ToString('N'))
 * npm install --prefix "$deps" --ignore-scripts --no-audit --no-fund --save-exact venice-ai-sdk-provider@2.1.1 ai@6.0.90
 * Esquema oficial: Python con jsonschema 4.24+ y referencing. Descargar UNA VEZ,
 * fuera del runner bloqueado; curl -q evita cargar .curlrc y no sigue redirects:
 * if (-not (Test-Path -LiteralPath $deps -PathType Container)) { throw 'Falta temporal' }
 * curl.exe -q --proto '=https' --fail --silent --show-error --max-time 60 --output "$deps/opencode-config-schema.json" https://opencode.ai/config.json
 * curl.exe -q --proto '=https' --fail --silent --show-error --max-time 60 --output "$deps/models-dev-model-schema.json" https://models.dev/model-schema.json
 * python -B tests/test_narrative_contracts.py --schema "$deps/opencode-config-schema.json" -v
 * node tests/verify-venice-request.mjs --deps "$deps" --schema "$deps/opencode-config-schema.json"
 * --schema es offline; espera models-dev-model-schema.json en el mismo directorio.
 * Sin el flag se informa NOT_REQUESTED, nunca se descarga ni se finge validacion.
 * Reutilizar el mismo $deps para repetir sin descargas; --python permite otro interprete.
 * El provider 2.1.1 publicado es V3. V2 se prueba con una fixture puente explicita,
 * no falsificando la version del modelo real ni afirmando que OpenCode se ejecuta.
 */

import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import http from 'node:http';
import https from 'node:https';
import net from 'node:net';
import tls from 'node:tls';
import { createRequire, syncBuiltinESMExports } from 'node:module';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { parseArgs } from 'node:util';

const { values } = parseArgs({ options: {
  deps: { type: 'string' }, python: { type: 'string', default: 'python' },
  schema: { type: 'string' },
  help: { type: 'boolean', default: false },
} });
if (values.help) {
  console.log('node tests/verify-venice-request.mjs --deps <prefijo-npm-temporal> [--schema <cache.json>] [--python python]');
  process.exit(0);
}
assert.ok(values.deps, 'Falta --deps; consulte los comandos al inicio del script.');
const deps = resolve(values.deps);
const requireDependency = createRequire(join(deps, 'package.json'));
const sha256 = data => createHash('sha256').update(data).digest('hex');
const networkAttempts = [];
const denyNetwork = (...args) => {
  networkAttempts.push(typeof args[0] === 'string' ? args[0] : 'socket/request');
  throw new Error('Red real prohibida: solo se permite el fetch MOCK inyectado.');
};
// Instalar antes de importar dependencias: tampoco puede escapar al fetch global.
globalThis.fetch = denyNetwork;
http.request = http.get = https.request = https.get = denyNetwork;
net.Socket.prototype.connect = denyNetwork;
tls.connect = denyNetwork;
syncBuiltinESMExports();

const packages = {};
async function loadPackage(name, expectedVersion) {
  const manifestPath = requireDependency.resolve(`${name}/package.json`);
  const manifest = JSON.parse(readFileSync(manifestPath, 'utf8'));
  assert.equal(manifest.version, expectedVersion, `Version inesperada de ${name}`);
  const entry = join(dirname(manifestPath), manifest.exports['.'].import);
  packages[name] = { version: manifest.version, entry, sha256: sha256(readFileSync(entry)) };
  return import(pathToFileURL(entry).href);
}

const { createVenice, VERSION } = await loadPackage('venice-ai-sdk-provider', '2.1.1');
const { generateText, streamText } = await loadPackage('ai', '6.0.90');
assert.equal(VERSION, '2.1.1');
const contractScript = join(dirname(fileURLToPath(import.meta.url)), 'test_narrative_contracts.py');
const contracts = JSON.parse(execFileSync(values.python, ['-B', contractScript, '--json',
  ...(values.schema ? ['--schema', resolve(values.schema)] : [])], {
  encoding: 'utf8', timeout: 30000,
}));
const warnings = [];
globalThis.AI_SDK_LOG_WARNINGS = event => warnings.push(event);
const captures = [];
const mockFetch = async (url, init) => {
  assert.equal(String(url), 'https://api.venice.ai/api/v1/chat/completions');
  assert.equal(init.method, 'POST');
  assert.equal(new Headers(init.headers).get('authorization'), 'Bearer test-not-a-secret');
  assert.equal(new Headers(init.headers).get('content-type'), 'application/json');
  assert.equal(typeof init.body, 'string');
  const body = JSON.parse(init.body);
  captures.push({ url: String(url), method: init.method, body,
    body_sha256: sha256(init.body) });
  if (body.stream === true) {
    const envelope = { id: 'mock-stream', object: 'chat.completion.chunk', created: 0, model: body.model };
    const chunks = [
      { choices: [{ index: 0, delta: { role: 'assistant', content: '' }, finish_reason: null }] },
      { choices: [{ index: 0, delta: { content: 'O' }, finish_reason: null }] },
      { choices: [{ index: 0, delta: { content: 'K' }, finish_reason: null }] },
      { choices: [{ index: 0, delta: {}, finish_reason: 'stop' }] },
      { choices: [], usage: { prompt_tokens: 3, completion_tokens: 1, total_tokens: 4 } },
    ];
    const wire = chunks.map(chunk => `data: ${JSON.stringify({ ...envelope, ...chunk })}\n\n`)
      .join('') + 'data: [DONE]\n\n';
    const bytes = new TextEncoder().encode(wire);
    // Fragmentar tambien dentro de JSON/lineas SSE: el parser real debe recomponerlos.
    const stream = new ReadableStream({ start(controller) {
      for (let offset = 0; offset < bytes.length; offset += 17) {
        controller.enqueue(bytes.slice(offset, offset + 17));
      }
      controller.close();
    } });
    return new Response(stream, { status: 200, headers: { 'content-type': 'text/event-stream' } });
  }
  // JSON neutral creado en memoria; ninguna delegacion a fetch ni a un servidor.
  return new Response(JSON.stringify({
    id: 'mock-neutral', object: 'chat.completion', created: 0, model: 'qwen-3-8-flash',
    choices: [{ index: 0, message: { role: 'assistant', content: 'OK' }, finish_reason: 'stop' }],
    usage: { prompt_tokens: 3, completion_tokens: 1, total_tokens: 4 },
  }), { status: 200, headers: { 'content-type': 'application/json' } });
};
const venice = createVenice({ apiKey: 'test-not-a-secret', fetch: mockFetch });
const model = venice.languageModel('qwen-3-8-flash');
assert.equal(venice.specificationVersion, 'v3');
assert.equal(model.specificationVersion, 'v3');
const messages = [{ role: 'user', content: [{ type: 'text', text: 'Responde OK.' }] }];

function assertPayload(capture, expectedLimit) {
  assert.equal(capture.body.max_completion_tokens, expectedLimit);
  assert.equal(typeof capture.body.max_completion_tokens, 'number');
  assert.equal(capture.body.model, 'qwen-3-8-flash');
  assert.deepEqual(capture.body.messages, [{ role: 'user', content: 'Responde OK.' }]);
  const forbidden = new Set(['tools', 'toolchoice', 'paralleltoolcalls', 'functions',
    'functioncall', 'reasoningeffort', 'reasoning', 'disablethinking', 'enablethinking',
    'maxoutputtokens', 'maxcompletiontokens', 'maxtokens']);
  function visit(value, path = '') {
    if (!value || typeof value !== 'object') return;
    for (const [key, child] of Object.entries(value)) {
      // El unico nombre permitido para el limite en el wire es snake_case.
      if (key !== 'max_completion_tokens') {
        assert.ok(!forbidden.has(key.replace(/_/g, '').toLowerCase()), `Campo prohibido ${path}.${key}`);
      }
      visit(child, `${path}.${key}`);
    }
  }
  visit(capture.body);
}

const results = [];
async function check(label, options, expectedLimit, route = model) {
  const before = captures.length;
  let result;
  if (label.startsWith('adapter/')) {
    result = await model.doGenerate({ prompt: messages, maxOutputTokens: 32000, ...options });
    assert.deepEqual(result.content, [{ type: 'text', text: 'OK' }]);
    assert.equal(result.finishReason.unified, 'stop');
    assert.equal(result.usage.inputTokens.total, 3);
    assert.equal(result.usage.outputTokens.total, 1);
  } else {
    result = await generateText({ model: route, messages, maxOutputTokens: 32000,
      maxRetries: 0, ...options });
    assert.equal(result.text, 'OK');
    assert.equal(result.finishReason, 'stop');
    assert.equal(result.usage.inputTokens, 3);
    assert.equal(result.usage.outputTokens, 1);
    assert.equal(result.totalUsage.totalTokens, 4);
  }
  assert.equal(captures.length, before + 1, 'Exactamente un fetch MOCK, sin retries');
  const capture = captures[before];
  assertPayload(capture, expectedLimit);
  assert.equal(capture.body.stream, false);
  results.push({ test: label, status: 'PASS', ...capture });
  return capture.body;
}

async function checkStream(label, options, expectedLimit, direct = false) {
  const before = captures.length;
  const parts = [];
  let text;
  if (direct) {
    const result = await model.doStream({ prompt: messages, maxOutputTokens: 32000, ...options });
    for await (const part of result.stream) parts.push(part);
    text = parts.filter(part => part.type === 'text-delta').map(part => part.delta).join('');
    const finish = parts.filter(part => part.type === 'finish');
    assert.equal(finish.length, 1);
    assert.equal(finish[0].finishReason.unified, 'stop');
    assert.equal(finish[0].usage.inputTokens.total, 3);
    assert.equal(finish[0].usage.outputTokens.total, 1);
  } else {
    const result = streamText({ model, messages, maxOutputTokens: 32000, maxRetries: 0, ...options });
    for await (const part of result.fullStream) parts.push(part);
    text = parts.filter(part => part.type === 'text-delta').map(part => part.text).join('');
    assert.equal(await result.text, 'OK');
    assert.equal(await result.finishReason, 'stop');
    assert.equal((await result.usage).inputTokens, 3);
    assert.equal((await result.usage).outputTokens, 1);
    assert.equal((await result.totalUsage).totalTokens, 4);
    const finish = parts.filter(part => part.type === 'finish');
    assert.equal(finish.length, 1);
    assert.equal(finish[0].finishReason, 'stop');
  }
  assert.equal(text, 'OK');
  assert.ok(!parts.some(part => part.type === 'error' || part.type.startsWith('tool-')));
  assert.equal(parts.filter(part => part.type === 'text-start').length, 1);
  assert.equal(parts.filter(part => part.type === 'text-end').length, 1);
  assert.equal(captures.length, before + 1, 'Exactamente un fetch SSE MOCK, sin retries');
  const capture = captures[before];
  assertPayload(capture, expectedLimit);
  assert.equal(capture.body.stream, true);
  results.push({ test: label, status: 'PASS', transport: 'mock-sse', text,
    finish_reason: 'stop', event_types: parts.map(part => part.type), ...capture });
  return capture.body;
}

const override = { providerOptions: { venice: { maxCompletionTokens: 64000 } } };
const directOverride = await check('adapter/override', override, 64000);
const directFallback = await check('adapter/fallback', {}, 32000);
assert.deepEqual(await check('sdk-v3/override', override, 64000), directOverride);
assert.deepEqual(await check('sdk-v3/fallback', {}, 32000), directFallback);
await check('sdk-v3/empty-tools', { ...override, tools: {} }, 64000);

const streamOverride = await checkStream('doStream/override', override, 64000, true);
const streamFallback = await checkStream('doStream/fallback', {}, 32000, true);
assert.deepEqual(await checkStream('streamText/override', override, 64000), streamOverride);
assert.deepEqual(await checkStream('streamText/fallback', {}, 32000), streamFallback);
await checkStream('streamText/empty-tools-override', { ...override, tools: {} }, 64000);
await checkStream('streamText/empty-tools-fallback', { tools: {} }, 32000);

for (const name of ['escritor', 'integrador']) {
  const config = contracts.agents[name].config;
  assert.deepEqual(config.permission, { '*': 'deny' });
  assert.deepEqual(config.options, { maxCompletionTokens: 64000 });
  assert.equal(config.model, `venice/${model.modelId}`);
  const options = {
    temperature: config.temperature, topP: config.top_p, topK: config.top_k,
    providerOptions: { venice: config.options },
  };
  for (const body of [await check(`agent-options/${name}`, options, 64000),
    await checkStream(`streamText/agent-options/${name}`, options, 64000)]) {
    assert.equal(body.temperature, config.temperature);
    assert.equal(body.top_p, config.top_p);
    assert.equal(body.top_k, config.top_k);
  }
}

// Fixture V2: usa el adaptador real para la peticion y convierte solo su respuesta
// al contrato V2. generateText ejecuta SU resolver V2 -> V3, no uno reimplementado.
let v2Calls = 0;
const v2Fixture = {
  specificationVersion: 'v2', provider: model.provider, modelId: model.modelId,
  supportedUrls: model.supportedUrls,
  async doGenerate(options) {
    v2Calls++;
    assert.equal(options.maxOutputTokens, 32000);
    const result = await model.doGenerate(options);
    return { ...result, finishReason: result.finishReason.unified, usage: {
      inputTokens: result.usage.inputTokens.total,
      outputTokens: result.usage.outputTokens.total,
      reasoningTokens: result.usage.outputTokens.reasoning,
      cachedInputTokens: result.usage.inputTokens.cacheRead,
    } };
  },
  doStream() { throw new Error('La fixture V2 no simula streaming.'); },
};
assert.deepEqual(await check('sdk-v2-fixture/override', override, 64000, v2Fixture), directOverride);
assert.deepEqual(await check('sdk-v2-fixture/fallback', {}, 32000, v2Fixture), directFallback);
assert.equal(v2Calls, 2);
assert.ok(warnings.some(event => event.warnings?.some(warning =>
  warning.type === 'compatibility' && warning.feature === 'specificationVersion')),
  'El resolver debe reconocer realmente la ruta V2');
assert.deepEqual(networkAttempts, []);
const lockBytes = readFileSync(join(deps, 'package-lock.json'));
const lock = JSON.parse(lockBytes);
console.log(JSON.stringify({
  status: 'PASS', tests: results.length, node: process.version, deps, packages,
  package_lock_sha256: sha256(lockBytes),
  provider_integrity: lock.packages['node_modules/venice-ai-sdk-provider'].integrity,
  contracts, actual_provider_api: model.specificationVersion,
  schema_validation: contracts.schema ?? { status: 'NOT_REQUESTED', hint: 'Use --schema <cache.json>' },
  v2: 'Fixture puente; resolver real de ai@6.0.90. El provider publicado no es V2.',
  network_attempts: networkAttempts.length, mock_requests: captures.length, results,
  streaming_tests: results.filter(result => result.transport === 'mock-sse').length,
  limitations: ['No ejecuta OpenCode ni verifica su merge runtime de opciones/permisos.',
    'Streaming SSE simulado con adaptador real; no inferencia real ni backend OpenCode.',
    'Esquema publicado estatico, no vinculado a la version instalada de OpenCode.',
    'El backend debe reiniciar para cargar cambios.',
    'No existe evidencia de una peticion real del backend actualizado hasta reinicio y captura.'],
}, null, 2));
