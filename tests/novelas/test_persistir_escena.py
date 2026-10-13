"""Pruebas aisladas: solo fixtures neutras y Qdrant/embedding simulados."""

import argparse
from contextlib import redirect_stderr, redirect_stdout
import copy
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import tempfile
import unittest
from unittest.mock import Mock, patch


HUB = Path(__file__).resolve().parents[2]
SCRIPT_SRC = HUB / "shared" / "pipelines" / "novela-simple" / "scripts" / "persistir-escena.py"
# El script importa qdrant.py del mismo directorio; se ensambla un stage temporal.
STAGE = Path(tempfile.mkdtemp(prefix="persistir-hub-"))
shutil.copy2(SCRIPT_SRC, STAGE / SCRIPT_SRC.name)
shutil.copy2(HUB / "scripts" / "qdrant.py", STAGE / "qdrant.py")
SCRIPT = STAGE / SCRIPT_SRC.name
SPEC = importlib.util.spec_from_file_location("persistir_escena", SCRIPT)
scene = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(scene)
TEMP_PARENT = Path(tempfile.gettempdir()) / "opencode"
TEMP_PARENT.mkdir(parents=True, exist_ok=True)
SID = "a19fc283"
FIRST = "c281fde9"
LAST = "e762a91c"
BIDS = ["d418ec02", "f813a49b"]
MARKER = f"<!-- ESCENA {SID}: Oficina -->\n"
CANDIDATE = (MARKER + f"\n## {BIDS[0]} [1]\n\nEl t\u00e9 espera.\n\n"
             + f"## {BIDS[1]} [2] Abrir la puerta\n\nLa puerta se abre.\n")
GUION = (
    "# Guion de prueba\n\n"
    f"<!-- ESCENA {FIRST}: Entrada -->\n\u2705 27ae80c1 [1] Entrar\n\n"
    + MARKER + f"\u2b1c {BIDS[0]} [1] Servir el te\n"
    + f"\U0001f504 {BIDS[1]} [2] Abrir la puerta\n\n"
    f"<!-- ESCENA {LAST}: Salida -->\n\u2705 412fec99 [1] Salir\n"
)
PREFIX = (f"# Capitulo\r\n\r\n<!-- ESCENA {FIRST}: Entrada -->\r\n"
          "\r\n## 27ae80c1 [1]\r\n\r\nLa oficina abre.\r\n"
          "\r\n### Notas del escritor\r\nConservar esta nota previa.\r\n\r\n").encode("utf-8")
SUFFIX = (f"<!-- ESCENA {LAST}: Salida -->\r\n\r\n## 412fec99 [1]\r\n\r\n"
          "La oficina cierra.\r\n\r\n### Notas del escritor\r\n"
          "No tocar esta nota ni el final.\r\n").encode("utf-8")


class PersistirEscenaTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(dir=TEMP_PARENT, prefix="persistir-test-")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.root = self.base / "workspace"
        self.chapter = self.root / "capitulos" / "cap-01-oficina"
        self.chapter.mkdir(parents=True)
        self.config = self.root / "config.json"
        self.config.write_text('{"slug":"prueba-aislada"}', encoding="utf-8")
        self.guion = self.chapter / "guion.md"
        self.guion.write_bytes(GUION.encode("utf-8"))
        self.source = self.root / "entrada.md"
        self.source.write_bytes(CANDIDATE.encode("utf-8"))
        self.pending = self.chapter / f"escena-{SID}.pendiente.md"
        self.draft = self.chapter / "draft.md"
        self.addCleanup(patch.stopall)
        patch.object(scene, "ROOT", self.root).start()
        # Cualquier llamada no simulada falla antes de poder alcanzar la red/modelo.
        self.http = patch.object(scene.backend, "qdrant", side_effect=AssertionError("Red real prohibida")).start()
        self.model = Mock()
        self.model.embed.side_effect = lambda texts: [Mock(tolist=Mock(return_value=[float(i), 1.0]))
                                                     for i, _ in enumerate(texts)]
        self.get_model = patch.object(scene.backend, "get_model", return_value=self.model).start()

    def args(self, command="preparar", **kwargs):
        values = {"command": command, "capitulo": str(self.chapter.relative_to(self.root)),
                  "escena": SID, "entrada": str(self.source), "finish": "stop", "revision": "{}"}
        values.update(kwargs)
        return argparse.Namespace(**values)

    def prepare(self):
        result = scene.run(self.args())
        # aceptar retira el candidato: las pruebas comparan con esta copia en memoria.
        self.candidate = self.pending.read_bytes()
        return result

    def review(self, **updates):
        # aceptar retira el candidato; la revision conserva el ultimo hash conocido.
        if self.pending.exists():
            self.candidate_hash = hashlib.sha256(self.pending.read_bytes()).hexdigest()
        review = {"escena_stable_id": SID, "candidato_sha256": self.candidate_hash,
                  "estado": "aprobado", "incidencias": []}
        review.update(updates)
        return json.dumps(review)

    def accept(self, **kwargs):
        return scene.run(self.args("aceptar", revision=self.review(), **kwargs))

    def sync(self, **kwargs):
        return scene.run(self.args("sincronizar", revision=self.review(), **kwargs))

    def points(self):
        return [{"id": scene.backend.make_point_id(bid), "payload": {
            "stable_id": bid, "proyecto": "prueba-aislada", "seq": index + 1,
            "parent_id": scene.backend.make_point_id(SID), "accion": "Accion de oficina",
            "tono": "neutro", "extension": "BREVE", "fichas": ["uuid-ficha-existente"],
            "vector_source": "guion", "narrative_text": None, "has_narrative": False,
            "extra": {"version": 3, "etiquetas": ["conservar"]},
        }, "vector": [0.0, 0.0]} for index, bid in enumerate(BIDS)]

    def fake_backend(self, points=None, failure=None):
        state = copy.deepcopy(self.points() if points is None else points)

        def request(method, path, data):
            if path == "/collections/beats/points":
                self.assertEqual(method, "POST")
                if "with_vector" not in data:
                    # Retrieve individual del helper cmd_update_beat, tambien simulado.
                    self.assertEqual(data, {"ids": [scene.backend.make_point_id(BIDS[0])],
                                            "with_payload": True})
                    return {"status": "ok", "result": copy.deepcopy([
                        point for point in state if point["id"] in data["ids"]])}
                self.assertEqual(data, {"ids": [scene.backend.make_point_id(bid) for bid in BIDS],
                                        "with_payload": True, "with_vector": False})
                return {"status": "ok", "result": copy.deepcopy(state)}
            if failure == "before":
                raise OSError("Backend no disponible")
            if path == "/collections/beats/points/payload?wait=true":
                self.assertEqual(method, "POST")
                for point in state:
                    if point["id"] in data["points"]:
                        point["payload"].update(copy.deepcopy(data["payload"]))
            else:
                self.assertEqual((method, path), ("PUT", "/collections/beats/points?wait=true"))
                for changed in data["points"]:
                    for index, point in enumerate(state):
                        if point["id"] == changed["id"]:
                            state[index] = copy.deepcopy(changed)
                            break
            if failure == "after":
                raise OSError("Timeout tras aplicar el lote")
            return {"status": "ok", "result": {"status": "completed"}}

        self.http.side_effect = request
        return state

    def prepare_and_accept(self):
        self.prepare()
        self.accept()

    def test_preparar_correcto(self):
        result = self.prepare()
        self.assertEqual(result["estado"], "pendiente")
        self.assertEqual(result["beat_stable_ids"], BIDS)
        self.assertEqual(result["proyecto"], "prueba-aislada")
        self.assertEqual(result["candidato_sha256"], hashlib.sha256(self.source.read_bytes()).hexdigest())
        self.assertEqual(self.pending.read_bytes(), self.source.read_bytes())
        self.assertFalse(self.draft.exists())
        self.http.assert_not_called()
        self.get_model.assert_not_called()

    def test_preparar_solo_normaliza_newlines(self):
        text = CANDIDATE.replace("El t\u00e9 espera.", "  El t\u00e9 espera.  ").rstrip("\n")
        original = text.replace("\n", "\r\n").encode("utf-8")
        self.source.write_bytes(original)
        result = self.prepare()
        self.assertTrue(result["normalizado"])
        self.assertEqual(self.pending.read_bytes(), (text + "\n").encode("utf-8"))
        self.assertEqual(self.source.read_bytes(), original)

    def test_preparar_reintento_no_op(self):
        self.prepare()
        before = self.pending.stat().st_mtime_ns
        self.assertFalse(self.prepare()["cambio"])
        self.assertEqual(before, self.pending.stat().st_mtime_ns)

    def test_preparar_rechazos_no_tocan_archivos(self):
        cases = {
            "vacio": "", "solo_blancos": " \n\t", "sin_marcador": CANDIDATE[len(MARKER):],
            "otro_marcador": CANDIDATE.replace(SID, LAST),
            "marcador_duplicado": CANDIDATE + MARKER,
            "marcador_malformado": CANDIDATE.replace(" -->", " ->"),
            "id_ajeno": CANDIDATE.replace(BIDS[0], "991182ab"),
            "duplicado": CANDIDATE.replace(BIDS[1], BIDS[0]),
            "faltante": CANDIDATE[:CANDIDATE.index(f"## {BIDS[1]}")],
            "orden": CANDIDATE.replace(BIDS[0], "TEMP").replace(BIDS[1], BIDS[0]).replace("TEMP", BIDS[1]),
            "seq": CANDIDATE.replace("[2]", "[3]"),
            "seq_cero": CANDIDATE.replace("[1]", "[0]"),
            "heading": CANDIDATE.replace("[1]", "1"),
            "cuerpo_vacio": CANDIDATE.replace("El t\u00e9 espera.", ""),
            "metatexto_previo": "Aqui tienes la escena:\n" + CANDIDATE,
            "texto_fuera_cuerpo": CANDIDATE.replace(MARKER, MARKER + "Texto extra\n"),
            "fence": CANDIDATE + "```\nnota\n```\n",
            "fence_tilde": CANDIDATE + "~~~text\nnota\n~~~\n",
            "nota_heading": CANDIDATE + "### Notas del escritor\nRevisar\n",
            "nota_texto": CANDIDATE + "Notas del escritor: revisar\n",
            "nota_bold": CANDIDATE + "**Notas del escritor:** revisar\n",
            "nota_corchetes": CANDIDATE + "[Nota: revisar]\n",
            "html": CANDIDATE + "<!-- Nota -->\n",
            "razonamiento": CANDIDATE + "<think>revisar</think>\n",
            "fin": CANDIDATE + "Fin de la escena.\n",
            "control": CANDIDATE + "\x00\n",
            "bom": "\ufeff" + CANDIDATE,
        }
        self.pending.write_bytes(b"candidato anterior\r\n")
        self.draft.write_bytes(PREFIX + SUFFIX)
        for name, text in cases.items():
            with self.subTest(name=name):
                self.source.write_bytes(text.encode("utf-8"))
                with self.assertRaises(ValueError):
                    self.prepare()
                self.assertEqual(self.pending.read_bytes(), b"candidato anterior\r\n")
                self.assertEqual(self.draft.read_bytes(), PREFIX + SUFFIX)
                self.assertEqual(self.source.read_bytes(), text.encode("utf-8"))
        self.http.assert_not_called()
        self.get_model.assert_not_called()

    def test_finish_length_vacio_y_ausente(self):
        self.pending.write_bytes(b"conservar")
        self.draft.write_bytes(PREFIX)
        for finish in ("length", "", None):
            with self.subTest(finish=finish), self.assertRaises(ValueError):
                scene.run(self.args(finish=finish))
        with redirect_stderr(io.StringIO()), self.assertRaises(SystemExit) as exit_info:
            scene.main(["preparar", "--capitulo", str(self.chapter), "--escena", SID,
                        "--entrada", str(self.source)])
        self.assertEqual(exit_info.exception.code, 2)
        self.assertEqual(self.pending.read_bytes(), b"conservar")
        self.assertEqual(self.draft.read_bytes(), PREFIX)

    def test_finish_invalido_cli_no_toca_escena_ya_aceptada(self):
        self.prepare_and_accept()
        before = {path: (path.read_bytes(), path.stat().st_mtime_ns)
                  for path in (self.draft, self.source, self.guion)}
        for finish in (["--finish", "length"], ["--finish", ""], []):
            with self.subTest(finish=finish), patch.object(scene, "read_guion") as reader:
                with redirect_stderr(io.StringIO()), self.assertRaises(SystemExit) as result:
                    scene.main(["preparar", "--capitulo", str(self.chapter), "--escena", SID,
                                "--entrada", str(self.source)] + finish)
                self.assertEqual(result.exception.code, 2)
                reader.assert_not_called()
        # aceptar retiro el candidato: preparar lo recrea y aceptar, sin cambiar el draft, lo vuelve a retirar.
        self.assertTrue(self.prepare()["cambio"])
        self.assertFalse(self.accept()["cambio"])
        self.assertFalse(self.pending.exists())
        self.assertEqual(before, {path: (path.read_bytes(), path.stat().st_mtime_ns) for path in before})
        self.assertEqual(list(self.chapter.glob("*.bak")), [])
        self.http.assert_not_called()

    def test_guion_ignora_ejemplos_en_fences(self):
        example = f"```text\n{MARKER}\u2b1c 991182ab [1] Ejemplo\n```\n"
        self.guion.write_text(example + GUION, encoding="utf-8")
        self.assertEqual(self.prepare()["beat_stable_ids"], BIDS)

    def test_guion_invalido_rechazado(self):
        for text in (GUION.replace("[2]", "[1]"), GUION.replace(BIDS[1], BIDS[0]),
                     GUION.replace(f"{BIDS[0]} [1]", f"{BIDS[0]} 1"),
                     GUION.replace("Servir el te", "-"),
                     GUION + MARKER, GUION + "```\n", GUION.replace(SID, "991182ab")):
            with self.subTest(text=text):
                self.guion.write_bytes(text.encode("utf-8"))
                with self.assertRaises(ValueError):
                    self.prepare()
                self.assertFalse(self.pending.exists())

    def test_etiqueta_visual_no_es_identidad(self):
        # ADR 0033: «B_NNNN · » delante del stable_id es solo para leer.
        etiquetado = (GUION.replace("✅ 27ae80c1", "✅ B_0001 · 27ae80c1")
                      .replace(f"⬜ {BIDS[0]}", f"⬜ B_0002 · {BIDS[0]}")
                      .replace(f"\U0001f504 {BIDS[1]}", f"\U0001f504 B_0007 · {BIDS[1]}"))
        self.guion.write_bytes(etiquetado.encode("utf-8"))
        self.assertEqual(scene.read_guion(self.guion)[SID]["beats"], [(BIDS[0], 1), (BIDS[1], 2)])
        self.assertEqual(self.prepare()["beat_stable_ids"], BIDS)
        self.assertEqual(self.accept()["estado"], "aceptado")
        # Sin el separador «·», la etiqueta se tomaría por identidad: se rechaza.
        self.guion.write_bytes(etiquetado.replace("B_0002 · ", "B_0002 ").encode("utf-8"))
        with self.assertRaises(ValueError):
            scene.read_guion(self.guion)

    def test_preparar_sin_limites_de_extension(self):
        for body in ("Te.", "La oficina espera. " * 500):
            with self.subTest(length=len(body)):
                self.source.write_bytes(CANDIDATE.replace("El t\u00e9 espera.", body).encode("utf-8"))
                self.assertEqual(self.prepare()["estado"], "pendiente")

    def test_revision_hash_obsoleto(self):
        self.prepare()
        self.draft.write_bytes(PREFIX)
        with self.assertRaisesRegex(ValueError, "Hash"):
            scene.run(self.args("aceptar", revision=self.review(candidato_sha256="0" * 64)))
        self.assertEqual(self.draft.read_bytes(), PREFIX)
        self.assertEqual(list(self.chapter.glob("*.bak")), [])

    def test_revision_bloqueante_o_malformada(self):
        self.prepare()
        cases = [{"estado": "rechazado"}, {"escena_stable_id": LAST}, {"incidencias": None},
                 {"incidencias": [{}]}, {"incidencias": ["opcional"]},
                 {"candidato_sha256": None}]
        cases += [{"incidencias": [{"gravedad": severity}]} for severity in
                  ("critica", "mayor", "menor", "advertencia", "Opcional", "", None, 0)]
        for updates in cases:
            with self.subTest(updates=updates), self.assertRaisesRegex(ValueError, "Esquema"):
                scene.run(self.args("aceptar", revision=self.review(**updates)))
        for raw in ("{}", "[]", "null", "42", "{malformado"):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                scene.run(self.args("aceptar", revision=raw))
        self.assertFalse(self.draft.exists())

    def test_revision_opcional_aceptada(self):
        self.prepare()
        result = scene.run(self.args("aceptar", revision=self.review(
            incidencias=[{"gravedad": "opcional", "detalle": "Observacion editorial"}], revisor="prueba")))
        self.assertEqual(result["estado"], "aceptado")

    def test_aceptar_crea_y_doble_retry_no_op(self):
        self.prepare()
        self.assertTrue(self.accept()["cambio"])
        before = self.draft.stat().st_mtime_ns
        for _ in range(2):
            self.assertFalse(self.accept()["cambio"])
        self.assertEqual(self.draft.stat().st_mtime_ns, before)
        self.assertEqual(list(self.chapter.glob("*.bak")), [])
        self.assertEqual(self.candidate, self.draft.read_bytes())
        self.assertFalse(self.pending.exists())
        self.assertEqual(self.guion.read_bytes(), GUION.encode("utf-8"))
        self.assertEqual(json.loads(self.config.read_text())["slug"], "prueba-aislada")
        self.http.assert_not_called()

    def test_aceptar_inserta_en_orden_sin_tocar_otros_bytes(self):
        self.prepare()
        original = PREFIX + SUFFIX
        self.draft.write_bytes(original)
        self.accept()
        self.assertEqual(self.draft.read_bytes(), PREFIX + self.candidate + SUFFIX)
        # El historial es el git de la obra: aceptar no deja copias del draft.
        self.assertEqual(list(self.chapter.glob("*.bak")), [])
        for _ in range(2):
            self.assertFalse(self.accept()["cambio"])
        self.assertEqual(list(self.chapter.glob("*.bak")), [])

    def test_aceptar_reemplaza_solo_escena(self):
        self.prepare()
        original = (PREFIX + CANDIDATE.replace("El t\u00e9 espera.", "La taza espera.").encode("utf-8")
                    + b"\n### Notas del escritor\nRetirar solo esta nota del borrador viejo.\n" + SUFFIX)
        self.draft.write_bytes(original)
        self.accept()
        self.assertEqual(self.draft.read_bytes(), PREFIX + self.candidate + SUFFIX)
        self.assertEqual(list(self.chapter.glob("*.bak")), [])
        self.assertFalse(self.accept()["cambio"])
        self.assertFalse(self.accept()["cambio"])

    def test_aceptar_inserta_antes_de_primera_existente(self):
        self.prepare()
        self.draft.write_bytes(b"# Cabecera\r\n\r\n" + SUFFIX)
        self.accept()
        self.assertEqual(self.draft.read_bytes(), b"# Cabecera\r\n\r\n" + self.candidate + SUFFIX)

    def test_aceptar_anade_al_final_sin_perder_prefijo(self):
        self.prepare()
        self.draft.write_bytes(PREFIX.rstrip(b"\r\n"))
        self.accept()
        self.assertEqual(self.draft.read_bytes(), PREFIX.rstrip(b"\r\n") + b"\n" + self.candidate)
        self.assertFalse(self.accept()["cambio"])

    def test_aceptar_revalida_guion_y_candidato(self):
        self.prepare()
        review = self.review()
        self.guion.write_bytes(GUION.replace("[2]", "[3]").encode("utf-8"))
        with self.assertRaises(ValueError):
            scene.run(self.args("aceptar", revision=review))
        self.guion.write_bytes(GUION.encode("utf-8"))
        self.pending.write_bytes(self.pending.read_bytes() + b"Notas del escritor: no\n")
        with self.assertRaises(ValueError):
            self.accept()
        self.assertFalse(self.draft.exists())

    def test_aceptar_rechaza_draft_ambiguo(self):
        self.prepare()
        for data in (SUFFIX + PREFIX, PREFIX + PREFIX, SUFFIX.replace(LAST.encode(), b"991182ab")):
            with self.subTest(data=data):
                self.draft.write_bytes(data)
                with self.assertRaises(ValueError):
                    self.accept()
                self.assertEqual(self.draft.read_bytes(), data)

    def test_traversal_y_otro_workspace_rechazados_antes_de_leer(self):
        for value in ("capitulos/../capitulos/cap-01-oficina", "../otro/capitulos/cap-01",
                      str(self.base / "otro" / "capitulos" / "cap-01"), str(self.root),
                      str(self.root / "capitulos")):
            with self.subTest(value=value), patch.object(scene, "read_guion") as reader:
                with self.assertRaises(ValueError):
                    scene.run(self.args(capitulo=value))
                reader.assert_not_called()
        for sid in ("../salir", "..", "a/b", "a\\b", "x:archivo", ""):
            with self.subTest(sid=sid), self.assertRaises(ValueError):
                scene.run(self.args(escena=sid))

    def test_entrada_externa_rechazada_y_temporal_permitido(self):
        with self.assertRaises(ValueError):
            scene.run(self.args(entrada="C:/fuera/otro-workspace/entrada.md"))
        external = self.base / "entrada-temporal.md"
        external.write_bytes(CANDIDATE.encode("utf-8"))
        self.assertEqual(scene.run(self.args(entrada=str(external)))["estado"], "pendiente")

    def test_archivo_entrada_no_puede_ser_pending(self):
        self.prepare()
        with self.assertRaises(ValueError):
            scene.run(self.args(entrada=str(self.pending)))

    def test_capitulo_absoluto_interno_permitido(self):
        self.assertEqual(scene.run(self.args(capitulo=str(self.chapter)))["estado"], "pendiente")

    def test_symlink_capitulo_externo_rechazado(self):
        target = self.base / "otro-tenant"
        target.mkdir()
        link = self.root / "capitulos" / "enlace"
        try:
            link.symlink_to(target, target_is_directory=True)
        except OSError as error:
            self.skipTest(f"El sistema no permite symlinks: {error}")
        with patch.object(scene, "read_guion") as reader, self.assertRaises(ValueError):
            scene.run(self.args(capitulo=str(link)))
        reader.assert_not_called()

    def test_capitulo_temporal_no_hereda_permiso_de_entrada(self):
        self.prepare_and_accept()
        review = self.review()
        before = self.draft.read_bytes(), self.pending.exists()
        target = self.base / "capitulo-temporal"
        target.mkdir()
        link = self.root / "capitulos" / "enlace-temporal"
        try:
            link.symlink_to(target, target_is_directory=True)
        except OSError as error:
            self.skipTest(f"El sistema no permite symlinks: {error}")
        for chapter in (target, link):
            for command in ("preparar", "aceptar", "sincronizar"):
                with self.subTest(chapter=chapter, command=command), patch.object(scene, "read_guion") as reader:
                    with self.assertRaises(ValueError):
                        scene.run(self.args(command, capitulo=str(chapter), revision=review))
                    reader.assert_not_called()
        self.assertEqual(list(target.iterdir()), [])
        self.assertEqual((self.draft.read_bytes(), self.pending.exists()), before)
        self.http.assert_not_called()

    def test_entrada_temporal_symlink_fuera_del_ambito_rechazado(self):
        allowed = self.base / "entradas-permitidas"
        allowed.mkdir()
        target = self.base / "entrada-ajena.md"
        target.write_bytes(CANDIDATE.encode("utf-8"))
        link = allowed / "enlace.md"
        try:
            link.symlink_to(target)
        except OSError as error:
            self.skipTest(f"El sistema no permite symlinks: {error}")
        with patch.object(scene, "TEMP_ROOT", allowed), patch.object(Path, "read_bytes") as reader:
            with self.assertRaises(ValueError):
                scene.run(self.args(entrada=str(link)))
            reader.assert_not_called()
        self.assertFalse(self.pending.exists())
        self.http.assert_not_called()

    def test_symlink_archivos_externos_rechazados(self):
        self.prepare()
        review = self.review()
        target = self.base / "ajeno.md"
        target.write_bytes(b"no leer ni modificar")
        for path, command in ((self.guion, "preparar"), (self.pending, "aceptar"),
                              (self.draft, "aceptar"), (self.config, "preparar")):
            with self.subTest(path=path):
                old = path.read_bytes() if path.exists() else None
                path.unlink(missing_ok=True)
                try:
                    path.symlink_to(target)
                except OSError as error:
                    self.skipTest(f"El sistema no permite symlinks: {error}")
                try:
                    with self.assertRaises(ValueError):
                        scene.run(self.args(command, revision=review))
                    self.assertEqual(target.read_bytes(), b"no leer ni modificar")
                finally:
                    path.unlink()
                    if old is not None:
                        path.write_bytes(old)

    def test_symlinks_salida_internos_no_sobrescriben_guion(self):
        self.prepare()
        review = self.review()
        for path, command in ((self.pending, "preparar"), (self.draft, "aceptar")):
            with self.subTest(path=path):
                old = path.read_bytes() if path.exists() else None
                path.unlink(missing_ok=True)
                try:
                    path.symlink_to(self.guion)
                except OSError as error:
                    self.skipTest(f"El sistema no permite symlinks: {error}")
                try:
                    with self.assertRaisesRegex(ValueError, "symlink"):
                        scene.run(self.args(command, revision=review))
                    self.assertEqual(self.guion.read_bytes(), GUION.encode("utf-8"))
                finally:
                    path.unlink()
                    if old is not None:
                        path.write_bytes(old)

    def test_capitulos_enlazado_a_otro_tenant_rechazado(self):
        original = self.root / "capitulos"
        moved = self.base / "capitulos-ajenos"
        original.rename(moved)
        try:
            original.symlink_to(moved, target_is_directory=True)
        except OSError as error:
            self.skipTest(f"El sistema no permite symlinks: {error}")
        with patch.object(scene, "read_guion") as reader, self.assertRaises(ValueError):
            self.prepare()
        reader.assert_not_called()

    def test_utf8_invalido_rechazado_sin_mutaciones(self):
        self.prepare()
        before = self.pending.read_bytes()
        self.source.write_bytes(b"\xff\xfe")
        with self.assertRaises(ValueError):
            self.prepare()
        self.assertEqual(self.pending.read_bytes(), before)
        self.assertFalse(self.draft.exists())

    def test_sincronizar_rechaza_revision_o_draft_distinto_sin_red(self):
        self.prepare_and_accept()
        with self.assertRaises(ValueError):
            scene.run(self.args("sincronizar", revision=self.review(candidato_sha256="0" * 64)))
        self.draft.write_bytes(self.draft.read_bytes().replace(b"puerta", b"oficina"))
        with self.assertRaises(ValueError):
            self.sync()
        self.http.assert_not_called()
        self.get_model.assert_not_called()

    def test_sincronizar_rechaza_sin_aceptacion(self):
        self.prepare()
        with self.assertRaises(ValueError):
            self.sync()
        self.http.assert_not_called()

    def test_sincronizar_revalida_guion_antes_de_red(self):
        self.prepare_and_accept()
        self.guion.write_bytes(GUION.replace(BIDS[1], "991182ab").encode("utf-8"))
        with self.assertRaises(ValueError):
            self.sync()
        self.http.assert_not_called()
        self.get_model.assert_not_called()

    def test_sincronizar_valida_todos_antes_de_embed_o_write(self):
        self.prepare_and_accept()
        variants = []
        for key, value in (("proyecto", "otro-tenant"), ("stable_id", "991182ab"),
                           ("parent_id", scene.backend.make_point_id(LAST)), ("parent_id", SID),
                           ("seq", 99), ("seq", True), ("seq", "2")):
            points = self.points()
            points[-1]["payload"][key] = value
            variants.append(points)
        variants.extend([[], self.points()[:1], self.points() + [self.points()[0]]])
        wrong_id = self.points()
        wrong_id[-1]["id"] = scene.backend.make_point_id("991182ab")
        variants.append(wrong_id)
        for points in variants:
            with self.subTest(points=points):
                self.http.reset_mock()
                self.fake_backend(points)
                with self.assertRaises(ValueError):
                    self.sync()
                self.assertEqual(self.http.call_count, 1)
                self.get_model.assert_not_called()

    def test_sincronizar_batch_preserva_metadata_y_solo_vectoriza_cuerpos(self):
        self.prepare()
        self.draft.write_bytes(PREFIX + SUFFIX)
        self.accept()
        before = self.draft.read_bytes()
        state = self.fake_backend()
        result = self.sync()
        self.assertEqual(result["estado"], "sincronizado")
        self.assertEqual(result["beats_actualizados"], 2)
        self.get_model.assert_called_once_with()
        self.model.embed.assert_called_once_with(["El t\u00e9 espera.", "La puerta se abre."])
        self.assertEqual([call.args[0] for call in self.http.call_args_list], ["POST", "PUT", "POST"])
        for old, new in zip(self.points(), state):
            for key in old["payload"].keys() - {"narrative_text", "vector_source", "has_narrative"}:
                self.assertEqual(new["payload"][key], old["payload"][key])
            self.assertEqual(new["payload"]["vector_source"], "narrativa")
            self.assertIs(new["payload"]["has_narrative"], True)
        self.assertEqual(self.draft.read_bytes(), before)
        self.assertEqual(self.guion.read_bytes(), GUION.encode("utf-8"))

    def test_sincronizar_no_op_evita_embedding(self):
        self.prepare_and_accept()
        self.fake_backend()
        self.sync()
        self.http.reset_mock()
        self.get_model.reset_mock()
        self.model.embed.reset_mock()
        for _ in range(2):
            self.assertEqual(self.sync()["beats_actualizados"], 0)
        self.get_model.assert_not_called()
        self.model.embed.assert_not_called()
        self.assertEqual([call.args[0] for call in self.http.call_args_list], ["POST", "POST"])

    def test_repara_flags_false_y_ausente_sin_embedding(self):
        self.prepare_and_accept()
        initial = self.points()
        for point, text in zip(initial, ("El t\u00e9 espera.", "La puerta se abre.")):
            point["payload"].update(narrative_text=text, vector_source="narrativa")
        del initial[0]["payload"]["has_narrative"]
        state = self.fake_backend(initial)
        result = self.sync()
        self.assertEqual(result["beats_actualizados"], 2)
        self.assertTrue(result["cambio"])
        self.assertEqual(self.http.call_count, 3)
        self.assertEqual(self.http.call_args_list[1].args, (
            "POST", "/collections/beats/points/payload?wait=true",
            {"points": [point["id"] for point in initial], "payload": {"has_narrative": True}},
        ))
        for old, new in zip(initial, state):
            self.assertEqual(new, dict(old, payload=dict(old["payload"], has_narrative=True)))
        self.http.reset_mock()
        for _ in range(2):
            self.assertEqual(self.sync()["beats_actualizados"], 0)
        self.assertEqual([call.args[1] for call in self.http.call_args_list],
                         ["/collections/beats/points"] * 2)
        self.get_model.assert_not_called()
        self.model.embed.assert_not_called()

    def test_flag_true_protege_vectores_de_cmd_update_beat(self):
        self.prepare_and_accept()
        for repair_only in (False, True):
            with self.subTest(repair_only=repair_only):
                initial = self.points()
                if repair_only:
                    for point, text in zip(initial, ("El t\u00e9 espera.", "La puerta se abre.")):
                        point["payload"].update(narrative_text=text, vector_source="narrativa")
                state = self.fake_backend(initial)
                self.assertEqual(self.sync()["beats_actualizados"], 2)
                for point in state:
                    self.assertIs(point["payload"]["has_narrative"], True)
                self.get_model.reset_mock()
                self.model.embed.reset_mock()
                self.assertEqual(self.sync()["beats_actualizados"], 0)
                before_update = copy.deepcopy(state)
                args = argparse.Namespace(proyecto="prueba-aislada", beat=BIDS[0],
                                          accion="Servir otro te", accion_file=None,
                                          tono=None, extension=None, parent_id=None, seq=None,
                                          fichas=None, fichas_file=None)
                self.http.reset_mock()
                with redirect_stdout(io.StringIO()), patch.object(
                        scene.backend, "embed", side_effect=AssertionError("No reemplazar vector narrativo")):
                    scene.backend.cmd_update_beat(args)
                before_update[0]["payload"]["accion"] = args.accion
                self.assertEqual(state, before_update)
                self.assertEqual([call.args[:2] for call in self.http.call_args_list], [
                    ("POST", "/collections/beats/points"),
                    ("POST", "/collections/beats/points/payload?wait=true"),
                ])
                self.get_model.assert_not_called()
                self.model.embed.assert_not_called()

    def test_lote_mixto_cuenta_flags_y_solo_embebe_texto_cambiado(self):
        self.prepare_and_accept()
        initial = self.points()
        initial[0]["payload"].update(narrative_text="El t\u00e9 espera.", vector_source="narrativa")
        state = self.fake_backend(initial)
        self.assertEqual(self.sync()["beats_actualizados"], 2)
        self.get_model.assert_called_once_with()
        self.model.embed.assert_called_once_with(["La puerta se abre."])
        self.assertEqual([call.args[:2] for call in self.http.call_args_list], [
            ("POST", "/collections/beats/points"),
            ("PUT", "/collections/beats/points?wait=true"),
            ("POST", "/collections/beats/points/payload?wait=true"),
            ("POST", "/collections/beats/points"),
        ])
        self.assertEqual(state[0]["vector"], initial[0]["vector"])
        self.assertTrue(all(point["payload"]["has_narrative"] is True for point in state))

    def test_reparacion_flags_valida_tenant_antes_de_escribir(self):
        self.prepare_and_accept()
        initial = self.points()
        for point, text in zip(initial, ("El t\u00e9 espera.", "La puerta se abre.")):
            point["payload"].update(narrative_text=text, vector_source="narrativa")
        initial[-1]["payload"]["proyecto"] = "otro-tenant"
        self.fake_backend(initial)
        with self.assertRaises(ValueError):
            self.sync()
        self.assertEqual(self.http.call_count, 1)
        self.get_model.assert_not_called()

    def test_reparacion_flags_exige_confirmacion_y_readback_booleano(self):
        self.prepare_and_accept()
        initial = self.points()
        for point, text in zip(initial, ("El t\u00e9 espera.", "La puerta se abre.")):
            point["payload"].update(narrative_text=text, vector_source="narrativa")
        retrieved = {"status": "ok", "result": initial}
        self.http.side_effect = [retrieved, {"status": "ok", "result": {"status": "acknowledged"}}]
        with self.assertRaisesRegex(ValueError, "no confirmada"):
            self.sync()
        for flag in (False, None, 1):
            with self.subTest(flag=flag):
                final = copy.deepcopy(initial)
                for point in final:
                    point["payload"]["has_narrative"] = flag
                self.http.side_effect = [retrieved, {"status": "ok", "result": {"status": "completed"}},
                                         {"status": "ok", "result": final}]
                with self.assertRaisesRegex(ValueError, "Readback"):
                    self.sync()
        self.get_model.assert_not_called()

    def test_fallo_reparacion_flags_retry_sin_embedding(self):
        self.prepare_and_accept()
        before = self.draft.read_bytes(), self.pending.exists()
        initial = self.points()
        for point, text in zip(initial, ("El t\u00e9 espera.", "La puerta se abre.")):
            point["payload"].update(narrative_text=text, vector_source="narrativa")
        for failure, remaining in (("before", 2), ("after", 0)):
            with self.subTest(failure=failure):
                state = self.fake_backend(initial, failure=failure)
                with self.assertRaises(OSError):
                    self.sync()
                self.fake_backend(state)
                self.assertEqual(self.sync()["beats_actualizados"], remaining)
                self.assertEqual(self.sync()["beats_actualizados"], 0)
                self.assertEqual((self.draft.read_bytes(), self.pending.exists()), before)
        self.get_model.assert_not_called()
        self.assertEqual(list(self.chapter.glob("*.bak")), [])

    def test_fallo_flags_tras_lote_vectorial_retry_solo_payload(self):
        self.prepare_and_accept()
        initial = self.points()
        initial[0]["payload"].update(narrative_text="El t\u00e9 espera.", vector_source="narrativa")
        state = self.fake_backend(initial)
        request = self.http.side_effect

        def fail_flags(method, path, data):
            if path == "/collections/beats/points/payload?wait=true":
                raise OSError("Fallo del segundo lote")
            return request(method, path, data)

        self.http.side_effect = fail_flags
        with self.assertRaises(OSError):
            self.sync()
        self.assertIs(state[0]["payload"]["has_narrative"], False)
        self.assertIs(state[1]["payload"]["has_narrative"], True)
        self.http.side_effect = request
        self.get_model.reset_mock()
        self.model.embed.reset_mock()
        self.assertEqual(self.sync()["beats_actualizados"], 1)
        self.assertEqual(self.sync()["beats_actualizados"], 0)
        self.get_model.assert_not_called()
        self.model.embed.assert_not_called()

    def test_sincronizar_solo_beats_cambiados(self):
        self.prepare_and_accept()
        points = self.points()
        points[0]["payload"].update(narrative_text="El t\u00e9 espera.", vector_source="narrativa", has_narrative=True)
        self.fake_backend(points)
        self.assertEqual(self.sync()["beats_actualizados"], 1)
        self.model.embed.assert_called_once_with(["La puerta se abre."])
        self.assertEqual(len(self.http.call_args_list[1].args[2]["points"]), 1)

    def test_sincronizar_mismo_texto_con_vector_guion_se_actualiza(self):
        self.prepare_and_accept()
        points = self.points()
        points[0]["payload"]["narrative_text"] = "El t\u00e9 espera."
        self.fake_backend(points)
        self.assertEqual(self.sync()["beats_actualizados"], 2)

    def test_fallo_backend_antes_write_retry_seguro(self):
        self.prepare_and_accept()
        before = self.draft.read_bytes()
        state = self.fake_backend(failure="before")
        with self.assertRaises(OSError):
            self.sync()
        self.assertEqual(state, self.points())
        self.assertEqual(self.draft.read_bytes(), before)
        self.fake_backend(state)
        self.assertEqual(self.sync()["beats_actualizados"], 2)
        self.assertEqual(self.sync()["beats_actualizados"], 0)
        self.assertEqual(self.draft.read_bytes(), before)
        self.assertEqual(list(self.chapter.glob("*.bak")), [])

    def test_timeout_despues_write_retry_no_duplica_ni_embebe(self):
        self.prepare_and_accept()
        state = self.fake_backend(failure="after")
        with self.assertRaises(OSError):
            self.sync()
        self.fake_backend(state)
        self.get_model.reset_mock()
        self.assertEqual(self.sync()["beats_actualizados"], 0)
        self.get_model.assert_not_called()
        self.assertEqual(len(state), 2)

    def test_backend_system_exit_se_propaga_sin_exito(self):
        self.prepare_and_accept()
        self.http.side_effect = SystemExit(1)
        with redirect_stdout(io.StringIO()) as output, self.assertRaises(SystemExit):
            scene.main(["sincronizar", "--capitulo", str(self.chapter), "--escena", SID,
                        "--revision", self.review()])
        self.assertEqual(output.getvalue(), "")
        self.assertTrue(self.draft.exists())

    def test_backend_respuesta_no_confirmada_o_readback_distinto(self):
        self.prepare_and_accept()
        retrieved = {"status": "ok", "result": self.points()}
        for write_response in ({"status": "error"}, {"status": "ok", "result": {"status": "acknowledged"}}):
            with self.subTest(response=write_response):
                self.http.side_effect = [retrieved, write_response]
                with self.assertRaisesRegex(ValueError, "no confirmada"):
                    self.sync()
        self.http.side_effect = [retrieved, {"status": "ok", "result": {"status": "completed"}}, retrieved]
        with self.assertRaisesRegex(ValueError, "Readback"):
            self.sync()

    def test_backend_retrieve_invalido_no_embebe(self):
        self.prepare_and_accept()
        for response in ({"status": "error"}, {"status": "ok", "result": {}},
                         {"status": "ok", "result": [{"id": "invalido", "payload": None}]}):
            with self.subTest(response=response):
                self.http.side_effect = None
                self.http.return_value = response
                with self.assertRaises(ValueError):
                    self.sync()
        self.get_model.assert_not_called()

    def test_readback_detecta_cambio_en_beat_omitido_del_lote(self):
        self.prepare_and_accept()
        initial = self.points()
        initial[0]["payload"].update(narrative_text="El t\u00e9 espera.", vector_source="narrativa", has_narrative=True)
        final = copy.deepcopy(initial)
        final[0]["payload"]["narrative_text"] = "Otro texto."
        final[1]["payload"].update(narrative_text="La puerta se abre.", vector_source="narrativa", has_narrative=True)
        self.http.side_effect = [
            {"status": "ok", "result": initial},
            {"status": "ok", "result": {"status": "completed"}},
            {"status": "ok", "result": final},
        ]
        with self.assertRaisesRegex(ValueError, "Readback"):
            self.sync()

    def test_embedding_incompleto_no_escribe(self):
        self.prepare_and_accept()
        self.fake_backend()
        self.model.embed.side_effect = None
        self.model.embed.return_value = []
        with self.assertRaisesRegex(ValueError, "incompleto"):
            self.sync()
        self.assertEqual(self.http.call_count, 1)

    def test_fallo_replace_conserva_original_y_limpia_temporal(self):
        self.prepare()
        self.draft.write_bytes(PREFIX + SUFFIX)
        with patch.object(scene.os, "replace", side_effect=OSError("archivo ocupado")):
            with self.assertRaises(OSError):
                self.accept()
        self.assertEqual(self.draft.read_bytes(), PREFIX + SUFFIX)
        self.assertEqual(list(self.chapter.glob(".persistir-*")), [])
        self.assertEqual(self.accept()["estado"], "aceptado")

    def test_cli_salida_json_y_error_no_cero(self):
        with redirect_stdout(io.StringIO()) as output:
            code = scene.main(["preparar", "--capitulo", str(self.chapter), "--escena", SID,
                               "--entrada", str(self.source), "--finish", "stop"])
        self.assertEqual(code, 0)
        self.assertEqual(json.loads(output.getvalue())["estado"], "pendiente")
        with redirect_stdout(io.StringIO()) as output, redirect_stderr(io.StringIO()) as errors:
            code = scene.main(["aceptar", "--capitulo", str(self.chapter), "--escena", SID,
                               "--revision", "{}"])
        self.assertEqual(code, 1)
        self.assertEqual(output.getvalue(), "")
        self.assertEqual(json.loads(errors.getvalue())["estado"], "error")

    def test_aceptar_y_sincronizar_limpian_solos_y_reintentan_desde_el_draft(self):
        self.prepare()
        entry = self.chapter / f"escena-{SID}.entrada.md"
        entry.write_bytes(self.candidate)
        live_pending = self.chapter / "escena-otra0001.pendiente.md"
        live_pending.write_text("candidato en curso\n", encoding="utf-8")
        old = self.pending.stat().st_mtime - 60
        for path in (entry, live_pending):
            os.utime(path, (old, old))

        accepted = self.accept()
        self.assertEqual(sorted(accepted["limpieza"]), sorted([entry.name, self.pending.name]))
        self.assertFalse(entry.exists() or self.pending.exists())
        self.assertTrue(live_pending.exists())
        # Sin candidato, los reintentos usan la escena del draft ligada al hash revisado.
        self.assertFalse(self.accept()["cambio"])
        self.fake_backend()
        self.assertEqual(self.sync()["beats_actualizados"], 2)
        self.assertEqual(self.sync()["beats_actualizados"], 0)
        with self.assertRaises(ValueError):
            scene.run(self.args("sincronizar", revision=self.review(candidato_sha256="0" * 64)))
        self.assertTrue(live_pending.exists())
        self.assertEqual(self.draft.read_bytes(), self.candidate)

    def test_limpiar_retira_lo_incorporado_y_conserva_lo_vivo(self):
        self.prepare_and_accept()
        # Restos anteriores a la limpieza automatica: limpiar es la via de contingencia.
        self.pending.write_bytes(self.candidate)
        before = self.draft.stat().st_mtime - 60
        consumed = [self.chapter / f"escena-{SID}.entrada.md", self.chapter / f"escena-{SID}.rev1.entrada.md"]
        for entry in consumed:
            entry.write_text("version anterior\n", encoding="utf-8")
            os.utime(entry, (before, before))
        newer = self.chapter / f"escena-{SID}.rev2.entrada.md"
        newer.write_text("trabajo sin preparar\n", encoding="utf-8")
        os.utime(newer, (before + 120, before + 120))
        live_pending = self.chapter / "escena-otra0001.pendiente.md"
        live_pending.write_text("candidato en curso\n", encoding="utf-8")
        live_entry = self.chapter / "escena-otra0001.entrada.md"
        live_entry.write_text("candidato en curso\n", encoding="utf-8")
        os.utime(live_entry, (before, before))
        draft, guion = self.draft.read_bytes(), self.guion.read_bytes()
        expected = sorted(p.name for p in consumed) + [self.pending.name]

        simulated = scene.run(self.args("limpiar", simular=True))
        self.assertEqual(simulated["estado"], "simulado")
        self.assertEqual(sorted(simulated["eliminados"]), sorted(expected))
        self.assertTrue(all(p.exists() for p in consumed + [self.pending]))

        with redirect_stdout(io.StringIO()) as output:
            self.assertEqual(scene.main(["limpiar", "--capitulo", str(self.chapter)]), 0)
        self.assertEqual(sorted(json.loads(output.getvalue())["eliminados"]), sorted(expected))
        self.assertFalse(any(p.exists() for p in consumed + [self.pending]))
        self.assertTrue(newer.exists() and live_pending.exists() and live_entry.exists())
        self.assertEqual((self.draft.read_bytes(), self.guion.read_bytes()), (draft, guion))
        self.assertEqual(scene.run(self.args("limpiar", simular=False))["eliminados"], [])

    def test_limpiar_sin_draft_conserva_todo_y_rechaza_fuera_del_ambito(self):
        self.prepare()
        self.assertEqual(scene.run(self.args("limpiar", simular=False))["eliminados"], [])
        self.assertTrue(self.pending.exists())
        with self.assertRaises(ValueError):
            scene.run(self.args("limpiar", capitulo="capitulos/../../fuera", simular=False))


if __name__ == "__main__":
    unittest.main()
