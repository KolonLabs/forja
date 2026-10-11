"""Regresiones estaticas, sin OpenCode, credenciales, red ni prosa generada.

Deps: Python 3.10+ y PyYAML (no se instala automaticamente).
Desde el workspace: python -B tests/test_narrative_contracts.py -v
Exportacion para el test Node: python -B tests/test_narrative_contracts.py --json
Esquema oficial offline (requiere jsonschema 4.24+ y su dependencia referencing):
python -B tests/test_narrative_contracts.py --schema <cache/config.json> -v
La cache debe incluir models-dev-model-schema.json junto al esquema principal.
Descargas publicas separadas: ver los comandos en verify-venice-request.mjs.
Sin --schema, los cuatro tests oficiales se omiten explicitamente. Nunca se
descargan referencias, ejecuta OpenCode ni se resuelven credenciales/plugins.
"""

import argparse
from copy import deepcopy
import hashlib
from importlib.metadata import version
import json
from pathlib import Path
import re
import sys
import unittest

try:
    import yaml
except ImportError as error:
    raise SystemExit("Falta PyYAML. Use un interprete con PyYAML instalado.") from error


HUB = Path(__file__).resolve().parents[2]
SIMPLE = HUB / "shared" / "pipelines" / "novela-simple"
AGENTS = ("escritor", "integrador", "validador")
WRITERS = AGENTS[:2]
FORBIDDEN_KEYS = {"reasoningeffort", "reasoning", "disablethinking", "enablethinking"}


def load_agents():
    agents = {}
    for name in AGENTS:
        path = SIMPLE / "agentes" / f"{name}.md"
        raw = path.read_bytes()
        lines = raw.decode("utf-8-sig").splitlines()
        if not lines or lines[0] != "---" or "---" not in lines[1:]:
            raise ValueError(f"{name}: falta frontmatter YAML delimitado")
        end = lines.index("---", 1)
        config = yaml.safe_load("\n".join(lines[1:end]))
        if not isinstance(config, dict):
            raise ValueError(f"{name}: el frontmatter debe ser un mapping")
        agents[name] = {"config": config, "body": "\n".join(lines[end + 1:]),
                        "sha256": hashlib.sha256(raw).hexdigest()}
    return agents


def load_official_schema(path):
    try:
        from jsonschema.validators import validator_for
        from referencing import Registry, Resource
    except ImportError as error:
        raise RuntimeError("--schema requiere jsonschema 4.24+ y referencing instalados") from error

    def deny_remote(uri):
        raise AssertionError(f"Referencia fuera de la cache; red prohibida: {uri}")

    path = path.resolve()
    registry = Registry(retrieve=deny_remote)
    documents = []
    schema = None
    validator_type = None
    for url, source in (
        ("https://opencode.ai/config.json", path),
        ("https://models.dev/model-schema.json", path.with_name("models-dev-model-schema.json")),
    ):
        raw = source.read_bytes()
        document = json.loads(raw)
        dialect = validator_for(document, default=None)
        if dialect is None:
            raise ValueError(f"Dialecto JSON Schema no soportado: {document.get('$schema')}")
        dialect.check_schema(document)
        registry = registry.with_resource(url, Resource.from_contents(document))
        documents.append({"url": url, "path": str(source), "bytes": len(raw),
                          "sha256": hashlib.sha256(raw).hexdigest(),
                          "dialect": document["$schema"]})
        if schema is None:
            schema, validator_type = document, dialect
    return validator_type(schema, registry=registry), {
        "validator": validator_type.__name__, "jsonschema": version("jsonschema"),
        "referencing": version("referencing"), "documents": documents,
        "remote_retrieval": "blocked", "scope": "Static Config.agent; no runtime OpenCode",
    }


def forbidden_keys(value, path=""):
    found = []
    if isinstance(value, dict):
        for key, child in value.items():
            child_path = f"{path}.{key}" if path else str(key)
            if re.sub(r"[^a-z]", "", str(key).lower()) in FORBIDDEN_KEYS:
                found.append(child_path)
            found.extend(forbidden_keys(child, child_path))
    elif isinstance(value, list):
        for index, child in enumerate(value):
            found.extend(forbidden_keys(child, f"{path}[{index}]"))
    return found


def tool_directives(body):
    # Linter lexico deliberadamente acotado; no pretende interpretar toda la prosa.
    patterns = (
        r"\b(?:carga|cargar|cargues|load|usa|usar|utiliza|utilizar|invoca|invocar|"
        r"ejecuta|ejecutar|consulta|consultar|lee|leer|use|invoke|run)\b"
        r"[^.\n;:]{0,100}\b(?:skills?|tools?|herramientas?|read|bash|qdrant|neo4j)\b",
        r"\b(?:persiste|persistir|persistas|sincroniza|sincronizar|sincronices|"
        r"actualiza|actualizar|guarda|guardar|escribe|escribir|upsert|persist|sync)\b"
        r"[^.\n;:]{0,100}\b(?:qdrant|neo4j|beats|narrative_text)\b",
        r"\b(?:skill|read|bash|qdrant|neo4j)\s*\(",
        r"\b(?:qdrant|neo4j)\.py\b",
    )
    found = []
    for pattern in patterns:
        for match in re.finditer(pattern, body, re.IGNORECASE):
            prefix = body[max(0, match.start() - 60):match.start()]
            if re.search(r"\b(?:la|una|su|esta)\s+$", prefix, re.IGNORECASE):
                continue  # Sustantivos: "la carga de skills", "una consulta".
            if not re.search(r"\b(?:no|ni|nunca|jamas)\s+(?:(?:debes|puedes)\s+)?$",
                             prefix, re.IGNORECASE):
                found.append(match.group())
    return found


class NarrativeContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.agents = load_agents()

    def test_frontmatter_shape(self):
        for name, agent in self.agents.items():
            with self.subTest(agent=name):
                config = agent["config"]
                self.assertEqual(config["mode"], "subagent")
                self.assertIs(config["hidden"], True)
                self.assertIsInstance(config["description"], str)
                self.assertTrue(config["description"].strip())
                self.assertIsInstance(config["model"], str)
                self.assertIn("/", config["model"])
                self.assertIsInstance(config["permission"], dict)
                self.assertNotIn("permissions", config)
                self.assertNotIn("tools", config)
                self.assertIsInstance(config["temperature"], (int, float))
                self.assertGreaterEqual(config["temperature"], 0)
                self.assertLessEqual(config["temperature"], 2)
                self.assertGreater(config["top_p"], 0)
                self.assertLessEqual(config["top_p"], 1)

    def test_writer_integrator_deny_all_without_exceptions(self):
        for name in WRITERS:
            with self.subTest(agent=name):
                self.assertEqual(self.agents[name]["config"]["permission"], {"*": "deny"})

    def test_validator_only_read_and_skill(self):
        self.assertEqual(self.agents["validador"]["config"]["permission"],
                         {"*": "deny", "read": "allow", "skill": "allow"})
        self.assertEqual(next(iter(self.agents["validador"]["config"]["permission"])), "*")

    def test_numeric_budget_is_agent_option_not_top_level(self):
        for name in WRITERS:
            with self.subTest(agent=name):
                config = self.agents[name]["config"]
                self.assertEqual(config["model"], "venice/qwen-3-8-flash")
                self.assertEqual(config["options"], {"maxCompletionTokens": 64000})
                self.assertIs(type(config["options"]["maxCompletionTokens"]), int)
                for key in ("maxCompletionTokens", "maxOutputTokens", "maxTokens",
                            "max_completion_tokens", "max_tokens", "providerOptions"):
                    self.assertNotIn(key, config)
                self.assertRegex(self.agents[name]["body"], r"maxCompletionTokens:\s*64000\b")

    def test_no_reasoning_or_thinking_configuration(self):
        for name, agent in self.agents.items():
            with self.subTest(agent=name):
                self.assertEqual(forbidden_keys(agent["config"]), [])
                self.assertNotRegex(agent["body"],
                                    r"(?i)\b(?:reasoning_?effort|disable_?thinking)\s*[:=]")

    def test_workspace_config_has_no_reasoning_override(self):
        # Solo JSON estatico local: no se resuelven imports, plugins ni credenciales.
        config = json.loads((HUB / "opencode.json").read_text(encoding="utf-8-sig"))
        self.assertEqual(forbidden_keys(config), [])

    def test_budget_is_not_a_literary_quota(self):
        for name in WRITERS:
            with self.subTest(agent=name):
                body = self.agents[name]["body"]
                self.assertRegex(body, r"(?i)no (?:una (?:meta|longitud)|es una meta)")
                self.assertNotRegex(body, r"(?i)\b(?:escribe|genera|produce)\s+"
                                         r"(?:al menos\s+)?[\d.,]+\s+(?:palabras|frases|tokens)\b")

    def test_stable_id_and_local_seq_headings(self):
        for name in WRITERS:
            with self.subTest(agent=name):
                body = self.agents[name]["body"]
                self.assertRegex(body, r"## <stable_id(?:_beat)?> \[<seq>\] \u2014")
                self.assertIn("orden recibido", body)
                self.assertRegex(body, r"(?i)\b(?:copia identidades|mismos stable_id|conserva acciones)")
        self.assertIn("<!-- ESCENA <stable_id_escena>: Nombre -->",
                      self.agents["escritor"]["body"])
        self.assertIn("no uses B_NNNN como identidad", self.agents["escritor"]["body"])
        self.assertIn("ni asignes IDs nuevos", self.agents["escritor"]["body"])

    def test_no_tool_loading_or_database_persistence_directives(self):
        for name in WRITERS:
            with self.subTest(agent=name):
                body = self.agents[name]["body"]
                self.assertEqual(tool_directives(body), [])
                self.assertRegex(body, r"(?i)herramientas estan deshabilitadas")
                self.assertIn("BLOQUEO:", body)

    def test_integrator_returns_only_requested_changes(self):
        body = self.agents["integrador"]["body"]
        self.assertIn("SOLO las secciones corregidas", body)
        self.assertIn("No incluyas los fragmentos intactos", body)
        self.assertIn("El director persiste", body)

    def test_linter_detects_regressions_and_preserves_explicit_denials(self):
        for directive in ("Antes de escribir, carga los skills de estilo.",
                          "Usa la herramienta read para obtener contexto.",
                          "Persiste el resultado en Qdrant.", "Sincroniza los beats.",
                          "Ejecuta qdrant.py.", "skill('estilo')", "Load the tools.",
                          "No cambies el canon; carga skills."):
            with self.subTest(directive=directive):
                self.assertTrue(tool_directives(directive))
        for denial in ("No carga skills.", "No debes cargar skills.",
                       "No persistas en Qdrant ni sincronices beats.",
                       "No lees archivos, no cargas skills ni sincronizas Qdrant.",
                       "Herramientas deshabilitadas, incluida la carga de skills.",
                       "No inventes una ruta, una consulta ni una herramienta."):
            with self.subTest(denial=denial):
                self.assertEqual(tool_directives(denial), [])

    def test_forbidden_key_scan_is_recursive(self):
        for key in ("reasoningEffort", "reasoning_effort", "disableThinking", "disable_thinking"):
            with self.subTest(key=key):
                self.assertEqual(forbidden_keys({"options": {"venice": [{key: False}]}}),
                                 [f"options.venice[0].{key}"])


class OfficialSchemaTests(unittest.TestCase):
    schema_path = None

    def setUp(self):
        if self.schema_path is None:
            self.skipTest("Falta --schema: no se solicita validacion oficial offline")

    @classmethod
    def setUpClass(cls):
        if cls.schema_path is not None:
            cls.validator, cls.report = load_official_schema(cls.schema_path)
            cls.payload = {"agent": {name: agent["config"] for name, agent in load_agents().items()}}
            print("SCHEMA " + json.dumps(cls.report), flush=True)

    def test_official_schema_accepts_all_three_frontmatters(self):
        errors = [f"{list(error.absolute_path)}: {error.validator}"
                  for error in self.validator.iter_errors(self.payload)]
        self.assertEqual(errors, [])

    def test_official_schema_rejects_invalid_permissions(self):
        for name in AGENTS:
            with self.subTest(agent=name):
                invalid = deepcopy(self.payload)
                invalid["agent"][name]["permission"] = {"*": "invalid-action"}
                self.assertFalse(self.validator.is_valid(invalid))

    def test_official_schema_requires_options_object(self):
        for name in WRITERS:
            with self.subTest(agent=name):
                invalid = deepcopy(self.payload)
                invalid["agent"][name]["options"] = 64000
                self.assertFalse(self.validator.is_valid(invalid))

    def test_official_schema_resolves_cached_model_enum(self):
        invalid = deepcopy(self.payload)
        invalid["agent"]["escritor"]["model"] = "test-not-a-provider/not-a-real-model"
        self.assertFalse(self.validator.is_valid(invalid))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("--schema", type=Path)
    parser.add_argument("--json", action="store_true")
    args, unittest_args = parser.parse_known_args()
    OfficialSchemaTests.schema_path = args.schema
    if args.json:
        if unittest_args:
            parser.error("--json no acepta argumentos adicionales de unittest")
        output = {"pyyaml": yaml.__version__, "agents": {
            name: {"config": agent["config"], "sha256": agent["sha256"]}
            for name, agent in load_agents().items()}}
        if args.schema:
            validator, report = load_official_schema(args.schema)
            validator.validate({"agent": {name: agent["config"] for name, agent in output["agents"].items()}})
            output["schema"] = {"status": "PASS", **report}
        print(json.dumps(output, ensure_ascii=True))
    else:
        print(f"PyYAML {yaml.__version__}; contrato estatico local; sin red", flush=True)
        for name, agent in load_agents().items():
            print(f"SHA256 {name}.md {agent['sha256']}", flush=True)
        unittest.main(argv=[sys.argv[0], *unittest_args])
