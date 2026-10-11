"""Salvaguardas estaticas del contrato multi-hilo; no ejecutan agentes ni BD."""

from pathlib import Path
import re
import unicodedata
import unittest

import yaml

HUB = Path(__file__).resolve().parents[2]
MULTI = HUB / "shared" / "pipelines" / "novela-multi-hilo"
SHARED = HUB / "shared"


def source(path):
    """Resuelve una ruta de workspace multi-hilo a la plantilla del hub."""
    if path.startswith(".opencode/agents/"):
        return MULTI / "agentes" / Path(path).name
    if path.startswith(".opencode/skills/"):
        name = Path(path).parts[2]
        override = MULTI / "skills" / name / "SKILL.md"
        return override if override.exists() else SHARED / "skills" / name / "SKILL.md"
    if path in ("PIPELINE.md", "ORQUESTACION.md"):
        return MULTI / path
    if path.startswith(".opencode/commands/"):
        return SHARED / ".opencode" / "commands" / Path(path).name
    raise ValueError(f"Ruta no mapeada: {path}")


def frontmatter(path):
    lines = source(path).read_text(encoding="utf-8-sig").splitlines()
    end = lines.index("---", 1)
    return yaml.safe_load("\n".join(lines[1:end]))


class MultiHiloContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        paths = [f".opencode/agents/{name}.md" for name in (
            "director", "guionista", "auditor-beats", "escritor", "integrador", "validador")]
        paths += [f".opencode/skills/{name}/SKILL.md" for name in (
            "beats-estructura", "contexto-subagente", "estructura-narrativa",
            "plantilla-guion", "validacion-cross-hilo")]
        paths += ["PIPELINE.md", "ORQUESTACION.md"]
        cls.texts = {}
        for path in paths:
            raw = source(path).read_text(encoding="utf-8-sig")
            text = unicodedata.normalize("NFKD", raw)
            text = "".join(c for c in text if not unicodedata.combining(c))
            cls.texts[path] = re.sub(r"\s+", " ", text.lower())

    def test_writers_have_no_tools_and_verified_budget(self):
        for name in ("escritor", "integrador"):
            with self.subTest(agent=name):
                config = frontmatter(f".opencode/agents/{name}.md")
                self.assertEqual(config["permission"], {"*": "deny"})
                self.assertEqual(config["model"], "venice/qwen-3-8-flash")
                self.assertEqual(config["options"], {"maxCompletionTokens": 64000})

    def test_specialists_use_deepseek_and_validator_is_cold(self):
        expected = {
            "director": "deepseek/deepseek-flash",
            "guionista": "deepseek/deepseek-flash",
            "auditor-beats": "deepseek/deepseek-flash",
            "validador": "deepseek/deepseek-flash",
        }
        for name, model in expected.items():
            with self.subTest(agent=name):
                config = frontmatter(f".opencode/agents/{name}.md")
                self.assertEqual(config["model"], model)
        validator = frontmatter(".opencode/agents/validador.md")
        self.assertEqual(validator["temperature"], 0.2)
        self.assertNotIn("top_k", validator)

    def test_scene_flow_and_human_checkpoint(self):
        for path in ("PIPELINE.md", "ORQUESTACION.md",
                     ".opencode/agents/director.md",
                     ".opencode/skills/contexto-subagente/SKILL.md"):
            with self.subTest(path=path):
                text = self.texts[path]
                self.assertIn("checkpoint", text)
                self.assertIn("escena", text)
                self.assertIn("hash", text)
        self.assertIn("persistir-escena.py", self.texts[".opencode/agents/director.md"])
        self.assertNotIn("beat a beat", self.texts["PIPELINE.md"])
        self.assertNotIn("score_global", self.texts["PIPELINE.md"])

    def test_quota_and_score_regressions_absent(self):
        regressions = ("score 1-10", "score_global", "espera ≥5 beats", "espera ≥6 beats",
                       "una sola oracion", "mas de una frase separada por punto",
                       "6-12", "3-8 beats", "minimo 3 beats")
        for path, text in self.texts.items():
            with self.subTest(path=path):
                for regression in regressions:
                    self.assertNotIn(regression, text)
        for name in ("guionista", "auditor-beats"):
            text = self.texts[f".opencode/agents/{name}.md"]
            self.assertIn("la ejecucion es del escritor", text)
            self.assertIn("cabecera de escena", text)
            self.assertIn("microcoreografia", text)

    def test_hilo_identity_and_crosshilo_incidences(self):
        self.assertIn("| hilo:", self.texts[".opencode/agents/escritor.md"])
        self.assertIn("| hilo:", self.texts[".opencode/skills/plantilla-guion/SKILL.md"])
        cross = self.texts[".opencode/skills/validacion-cross-hilo/SKILL.md"]
        self.assertIn("incidencias", cross)
        self.assertIn("gravedad", cross)
        self.assertNotIn("score", cross)
        contexto = self.texts[".opencode/skills/contexto-subagente/SKILL.md"]
        self.assertIn("canonico de la escena", contexto)
        self.assertIn("checkpoint", contexto)

    def test_seq_is_local_to_parent(self):
        self.assertIn("local a su escena padre", self.texts["PIPELINE.md"])
        self.assertIn("local al `parent_id`", self.texts[".opencode/skills/beats-estructura/SKILL.md"])
        self.assertIn("renumber-siblings", self.texts[".opencode/skills/beats-estructura/SKILL.md"])



    def test_explicit_scenes_show_not_tell(self):
        for path in (".opencode/agents/escritor.md", ".opencode/agents/integrador.md",
                     ".opencode/agents/validador.md", ".opencode/agents/director.md",
                     ".opencode/skills/contexto-subagente/SKILL.md", "ORQUESTACION.md"):
            with self.subTest(path=path):
                self.assertIn("sentencias que cuentan", self.texts[path])
        self.assertIn("progresion", self.texts[".opencode/agents/escritor.md"])

if __name__ == "__main__":
    unittest.main()
