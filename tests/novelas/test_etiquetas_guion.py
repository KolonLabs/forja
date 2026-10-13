"""Etiquetas visuales de guion (ADR 0033): inserción, numeración global e idempotencia."""

import importlib.util
import io
import json
from contextlib import redirect_stdout
from pathlib import Path
import shutil
import tempfile
import unittest

HUB = Path(__file__).resolve().parents[2]
SCRIPTS = HUB / "shared" / "pipelines" / "novela-simple" / "scripts"
STAGE = Path(tempfile.mkdtemp(prefix="etiquetas-hub-"))
for nombre in ("etiquetas-guion.py", "persistir-escena.py"):
    shutil.copy2(SCRIPTS / nombre, STAGE / nombre)
shutil.copy2(HUB / "scripts" / "qdrant.py", STAGE / "qdrant.py")


def cargar(nombre, modulo):
    spec = importlib.util.spec_from_file_location(modulo, STAGE / nombre)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


etiquetas = cargar("etiquetas-guion.py", "etiquetas_guion")
persistir = cargar("persistir-escena.py", "persistir_escena_etiquetas")
OK, PEND = "✅", "⬜"

CAP1 = (
    "# Capítulo cap-01-inicio — El inicio\n\n"
    "<!-- ESCENA aaaa1111: La llegada -->\n\n"
    "**Personajes:** Elena\n\n"
    f"{OK} B_0050 · a1b2c3d4 [1] — Llega.\n"
    f"{OK} a1b2c3d5 [2] — Mira.\n\n"
    "<!-- ESCENA bbbb2222: La duda | hilo: hilo0001 -->\n"
    "### E_0009 — Nombre viejo\n\n"
    f"- {PEND} B_0003 · b1b2c3d4 [1] — Duda.\n\n"
    "```\n<!-- ESCENA ejemplo1: No es real -->\n"
    f"{PEND} e1e2e3e4 [1] — Ejemplo.\n```\n"
)
CAP2 = (
    "# Capítulo cap-02-fin — El fin\r\n\r\n"
    "<!-- ESCENA cccc3333: La salida -->\r\n"
    f"{PEND} c1b2c3d4 [1] — Sale.\r\n"
)


class EtiquetasGuionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="etiquetas-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.cap1 = self.root / "capitulos" / "cap-01-inicio" / "guion.md"
        self.cap2 = self.root / "capitulos" / "cap-10-fin" / "guion.md"
        self.cap1.parent.mkdir(parents=True)
        self.cap2.parent.mkdir(parents=True)
        self.cap1.write_bytes(CAP1.encode("utf-8"))
        self.cap2.write_bytes(CAP2.encode("utf-8"))

    def run_script(self, *args):
        with redirect_stdout(io.StringIO()) as salida:
            self.assertEqual(etiquetas.main(["--obra", str(self.root), *args]), 0)
        return json.loads(salida.getvalue())

    def test_numeracion_global_en_orden_de_lectura(self):
        antes = persistir.read_guion(self.cap1), persistir.read_guion(self.cap2)
        resultado = self.run_script()
        self.assertEqual(resultado["ambitos"][0]["beats"], 4)
        self.assertEqual(resultado["ambitos"][0]["escenas"], 3)
        cap1 = self.cap1.read_text(encoding="utf-8")
        self.assertIn(f"{OK} B_0001 · a1b2c3d4 [1] — Llega.", cap1)
        self.assertIn(f"{OK} B_0002 · a1b2c3d5 [2] — Mira.", cap1)
        self.assertIn(f"- {PEND} B_0003 · b1b2c3d4 [1] — Duda.", cap1)
        self.assertIn("<!-- ESCENA aaaa1111: La llegada -->\n### E_0001 — La llegada\n\n**Personajes:**", cap1)
        self.assertIn("### E_0002 — La duda\n", cap1)
        self.assertNotIn("Nombre viejo", cap1)
        self.assertIn(f"```\n<!-- ESCENA ejemplo1: No es real -->\n{PEND} e1e2e3e4 [1]", cap1)
        cap2 = self.cap2.read_bytes()
        self.assertIn(f"{PEND} B_0004 · c1b2c3d4 [1] — Sale.\r\n".encode("utf-8"), cap2)
        self.assertIn("### E_0003 — La salida\r\n".encode("utf-8"), cap2)
        # La identidad no cambia: mismas escenas, beats y seq.
        self.assertEqual((persistir.read_guion(self.cap1), persistir.read_guion(self.cap2)), antes)

    def test_idempotente_y_simulacion(self):
        original = self.cap1.read_bytes()
        simulado = self.run_script("--simular")
        self.assertEqual(simulado["estado"], "simulado")
        self.assertEqual(self.cap1.read_bytes(), original)
        self.run_script()
        primera = self.cap1.read_bytes(), self.cap2.read_bytes()
        self.assertEqual(self.run_script()["ambitos"][0]["cambiados"], [])
        self.assertEqual((self.cap1.read_bytes(), self.cap2.read_bytes()), primera)

    def test_insertar_un_beat_renumera_los_siguientes(self):
        self.run_script()
        texto = self.cap1.read_text(encoding="utf-8").replace(
            f"{OK} B_0002 · a1b2c3d5 [2] — Mira.\n",
            f"{OK} B_0002 · a1b2c3d5 [2] — Mira.\n{PEND} f0f0f0f0 [3] — Nuevo.\n")
        self.cap1.write_text(texto, encoding="utf-8")
        self.run_script()
        cap1 = self.cap1.read_text(encoding="utf-8")
        self.assertIn(f"{PEND} B_0003 · f0f0f0f0 [3] — Nuevo.", cap1)
        self.assertIn(f"B_0004 · b1b2c3d4", cap1)
        self.assertIn(f"B_0005 · c1b2c3d4", self.cap2.read_text(encoding="utf-8"))

    def test_notas_refrescan_parejas_y_avisan_huerfanas(self):
        notas = self.cap1.parent / "notas-escritor.md"
        notas.write_text("Continuidad con B_0099 · a1b2c3d5 y la escena E_0007 · bbbb2222.\n"
                         "Huérfana: B_0001 · zzzz9999. Suelta: B_0050.\n"
                         "Rango: B_0099 · a1b2c3d4-B_0098 · a1b2c3d5.\n", encoding="utf-8")
        resultado = self.run_script()["ambitos"][0]
        texto = notas.read_text(encoding="utf-8")
        self.assertIn("B_0002 · a1b2c3d5", texto)
        self.assertIn("E_0002 · bbbb2222", texto)
        self.assertIn("B_0001 · zzzz9999", texto)
        self.assertIn("Suelta: B_0050.", texto)
        self.assertIn("Rango: B_0001 · a1b2c3d4-B_0002 · a1b2c3d5.", texto)
        self.assertEqual(resultado["parejas_huerfanas"], ["capitulos/cap-01-inicio/notas-escritor.md: B_0001 · zzzz9999"])
        self.assertIn("capitulos/cap-01-inicio/notas-escritor.md", resultado["cambiados"])

    def test_renumerar_devuelve_referencias_sueltas_para_revisar(self):
        self.run_script()
        # Se inserta un beat: los siguientes se renumeran.
        texto = self.cap1.read_text(encoding="utf-8").replace(
            f"{OK} B_0002 · a1b2c3d5 [2] — Mira.\n",
            f"{OK} B_0002 · a1b2c3d5 [2] — Mira.\n{PEND} f0f0f0f0 [3] — Nuevo.\n> Nota de pasada: B_0003 abre la duda.\n"
            "> Nota invertida: el beat `c1b2c3d4` [B_0004] cierra.\n")
        self.cap1.write_text(texto, encoding="utf-8")
        (self.root / "contexto.md").write_text("Revisado el B_0003 y la escena E_0002.\n", encoding="utf-8")
        (self.root / "GUIA.md").write_text("Ejemplo: /revisar B_0003\n", encoding="utf-8")
        notas = self.cap1.parent / "notas-escritor.md"
        notas.write_text("Pareja B_0003 · b1b2c3d4 y suelta B_0004. Invertida `b1b2c3d4` (B_0003).\n", encoding="utf-8")

        resultado = self.run_script("--tabla")
        ambito = resultado["ambitos"][0]
        self.assertEqual(ambito["renumeradas"], 2)
        self.assertEqual(ambito["nuevas"], 1)
        self.assertIn({"antes": "B_0003", "ahora": "B_0004", "stable_id": "b1b2c3d4"}, ambito["tabla"])
        refs = {(r["archivo"], r["etiqueta"], r["ahora"], r["stable_id"]) for r in ambito["referencias"]}
        self.assertEqual(refs, {
            ("contexto.md", "B_0003", "B_0004", "b1b2c3d4"),
            ("capitulos/cap-01-inicio/guion.md", "B_0003", "B_0004", "b1b2c3d4"),
            ("capitulos/cap-01-inicio/notas-escritor.md", "B_0004", "B_0005", "c1b2c3d4"),
        })
        self.assertIn("siguiente_paso", resultado)
        # La pareja se actualiza sola y no se cuenta como referencia; las sueltas no se tocan.
        self.assertEqual(notas.read_text(encoding="utf-8"),
                         "Pareja B_0004 · b1b2c3d4 y suelta B_0004. Invertida B_0004 · b1b2c3d4.\n")
        # La forma invertida del propio guion pasa a la canónica, con el mapa de todo el ámbito.
        self.assertIn("> Nota invertida: el beat B_0005 · c1b2c3d4 cierra.", self.cap1.read_text(encoding="utf-8"))
        self.assertIn("Revisado el B_0003", (self.root / "contexto.md").read_text(encoding="utf-8"))
        # Sin cambios, no hay referencias que revisar.
        self.assertEqual(self.run_script()["ambitos"][0]["referencias"], [])

    def test_qdrant_rechaza_etiquetas_como_identidad(self):
        qdrant = cargar("qdrant.py", "qdrant_etiquetas")
        for etiqueta in ("B_0212", "E_0041", "H_0001"):
            with self.subTest(etiqueta=etiqueta), self.assertRaises(SystemExit):
                qdrant.make_point_id(etiqueta)
        self.assertEqual(qdrant.make_point_id("4c1e7a2d"), qdrant.make_point_id("4c1e7a2d"))

    def test_hilos_numeran_por_su_cuenta(self):
        for hilo in ("hilo-a", "hilo-b"):
            guion = self.root / "hilos" / hilo / "cap-01" / "guion.md"
            guion.parent.mkdir(parents=True)
            guion.write_text("<!-- ESCENA dddd4444: Uno -->\n" f"- {PEND} d1d2d3d4 [1] — Algo.\n", encoding="utf-8")
        ambitos = {a["ambito"]: a for a in self.run_script()["ambitos"]}
        self.assertEqual(set(ambitos), {"capitulos", "hilos/hilo-a", "hilos/hilo-b"})
        for hilo in ("hilo-a", "hilo-b"):
            texto = (self.root / "hilos" / hilo / "cap-01" / "guion.md").read_text(encoding="utf-8")
            self.assertIn(f"- {PEND} B_0001 · d1d2d3d4 [1]", texto)
            self.assertIn("### E_0001 — Uno", texto)


if __name__ == "__main__":
    unittest.main()
