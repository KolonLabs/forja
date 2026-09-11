"""Salvaguardas estaticas de prompts; no prueban calidad ni ejecutan agentes/BD."""

from pathlib import Path
import re
import unicodedata
import unittest


ROOT = Path(__file__).resolve().parents[1]
AGENTS = ("guionista", "auditor-beats", "director", "escritor", "integrador", "validador")
SKILLS = ("beats-estructura", "contexto-subagente", "hechos-estructura",
          "estructura-narrativa", "plantilla-guion", "mecanica-prosa",
          "tonos-beat", "consistencia-narrativa", "validacion-geometria",
          "hechos-distribuidos", "validacion-tono", "validacion-coherencia")


class BeatContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        paths = [f".opencode/agents/{name}.md" for name in AGENTS]
        paths += [f".opencode/skills/{name}/SKILL.md" for name in SKILLS]
        paths += ["PIPELINE.md", "ORQUESTACION.md"]
        paths += [f".opencode/commands/{name}.md" for name in ("generar", "revisar", "expandir")]
        cls.texts = {}
        for path in paths:
            raw = (ROOT / path).read_text(encoding="utf-8-sig")
            # Comparar reglas sin depender de tildes, mayusculas o salto de linea.
            text = unicodedata.normalize("NFKD", raw)
            text = "".join(c for c in text if not unicodedata.combining(c))
            cls.texts[path] = re.sub(r"\s+", " ", text.lower())

    def test_context_separates_obligations_freedom_and_examples(self):
        for path in [f".opencode/agents/{name}.md" for name in AGENTS] + [
            ".opencode/skills/beats-estructura/SKILL.md",
            ".opencode/skills/contexto-subagente/SKILL.md", "ORQUESTACION.md",
        ]:
            with self.subTest(path=path):
                for term in ("obligatorio", "libre", "ejemplos opcionales"):
                    self.assertIn(term, self.texts[path])

    def test_no_counting_rules_or_punctuation_driven_splitting(self):
        regressions = (
            "una sola accion con principio y fin visibles",
            "mas de una frase separada por punto",
            "12-18 beats", "3-8 beats", "minimo 3 beats",
            "espera ≥5 beats", "espera ≥6 beats", "menos de 3 → subdesarrollado",
            "2-3 por defecto", "si necesita tres, el beat esta demasiado cargado",
        )
        for path, text in self.texts.items():
            with self.subTest(path=path):
                for regression in regressions:
                    self.assertNotIn(regression, text)
        for name in ("guionista", "auditor-beats"):
            text = self.texts[f".opencode/agents/{name}.md"]
            self.assertIn("puntuacion", text)
            self.assertIn("consecuencia", text)
            self.assertIn("la ejecucion es del escritor", text)
            self.assertIn("cabecera de escena", text)

    def test_information_and_interiority_not_forced_into_dialogue(self):
        for name in AGENTS:
            with self.subTest(agent=name):
                text = self.texts[f".opencode/agents/{name}.md"]
                for term in ("dicho", "sabido", "inferido", "confirmado"):
                    self.assertIn(term, text)
                self.assertRegex(text, r"conf(?:esion|iese)")

    def test_literal_words_require_authority_and_conflicts_are_escalated(self):
        for path in (".opencode/skills/beats-estructura/SKILL.md",
                     ".opencode/skills/mecanica-prosa/SKILL.md",
                     ".opencode/agents/guionista.md",
                     ".opencode/agents/auditor-beats.md"):
            with self.subTest(path=path):
                text = self.texts[path]
                for term in ("usuario", "causal", "director", "conflicto"):
                    self.assertIn(term, text)
                self.assertRegex(text, r"literalidad|palabras exactas")
        for name in ("escritor", "integrador"):
            text = self.texts[f".opencode/agents/{name}.md"]
            self.assertIn("bloqueo:", text)
            self.assertIn("literalidad", text)

    def test_scene_continuity_preserves_technical_sections(self):
        for name in ("escritor", "integrador"):
            with self.subTest(agent=name):
                text = self.texts[f".opencode/agents/{name}.md"]
                for term in ("trazabilidad", "no vacio", "despedidas", "seq"):
                    self.assertIn(term, text)
                self.assertRegex(text, r"saludos|aperturas")
                self.assertRegex(text, r"## <stable_id(?:_beat)?> \[<seq>\]")

    def test_integrator_has_full_context_and_repairs_mechanism(self):
        text = self.texts[".opencode/agents/integrador.md"]
        for term in ("mecanismo", "alcance", "completa", "bloqueo:",
                     "secciones corregidas", "mismos stable_id"):
            self.assertIn(term, text)
        self.assertIn("no reconstruyas lo que no recibiste", text)

    def test_validator_checks_naturalness_not_only_ids(self):
        text = self.texts[".opencode/agents/validador.md"]
        self.assertIn("naturalidad es `corregir`", text)
        self.assertIn("resumen editorial disfrazado", text)
        self.assertIn("no apruebes por checklist mecanico", text)

    def test_tones_do_not_create_conduct_or_knowledge(self):
        text = self.texts[".opencode/skills/tonos-beat/SKILL.md"]
        self.assertIn("no altera hechos, conducta, conocimiento", text)
        for regression in ("el que obedece no pregunta", "cada instruccion se cumple",
                           "sin reflexion", "sin subtexto"):
            self.assertNotIn(regression, text)

    def test_prose_mechanics_dont_force_paragraphs_or_thought_lists(self):
        text = self.texts[".opencode/skills/mecanica-prosa/SKILL.md"]
        self.assertIn("pensamiento directo", text)
        self.assertIn("indirecto libre", text)
        self.assertIn("no toda interioridad", text)
        self.assertIn("sin listas obligatorias", text)
        self.assertNotIn("6-7 lineas", text)
        self.assertNotIn("lo documenta al final del texto", text)

    def test_director_preserves_user_checkpoint(self):
        for path in (".opencode/agents/director.md", "PIPELINE.md", "ORQUESTACION.md",
                     ".opencode/skills/contexto-subagente/SKILL.md"):
            with self.subTest(path=path):
                text = self.texts[path]
                self.assertIn("checkpoint obligatorio de narrativa", text)
                self.assertIn("escena completa", text)
                self.assertRegex(text, r"det(?:en(?:te|erse)|iene)")
                self.assertNotIn("si el usuario pide validar escena a escena", text)
        text = self.texts[".opencode/agents/director.md"]
        self.assertIn("no aceptes ni sincronices", text)
        self.assertIn("conformidad explicita del usuario y revision `aprobado`", text)
        self.assertIn("espera conformidad del usuario antes del paso 4", text)
        self.assertIn("registro obligatorio en cada checkpoint", text)
        self.assertNotIn("resumen post-capitulo (opcional", text)
        orchestration = self.texts["ORQUESTACION.md"]
        self.assertNotIn("`✅` (validador aprueba)", orchestration)
        self.assertIn("sincronizacion exitosa", orchestration)
        self.assertIn("registro obligatorio en cada checkpoint", orchestration)

    def test_new_text_requires_new_user_validation(self):
        for path in (".opencode/agents/director.md", "PIPELINE.md", "ORQUESTACION.md",
                     ".opencode/skills/contexto-subagente/SKILL.md"):
            with self.subTest(path=path):
                self.assertIn("cualquier cambio textual invalida la conformidad anterior",
                              self.texts[path])
        text = self.texts[".opencode/agents/director.md"]
        self.assertIn("contexto.md", text)
        self.assertIn("no inventes aprobacion", text)
        self.assertIn("candidata existente y pregunta", text)

    def test_scene_approval_does_not_start_next_chapter(self):
        for path in (".opencode/agents/director.md", "PIPELINE.md", "ORQUESTACION.md",
                     ".opencode/commands/generar.md"):
            with self.subTest(path=path):
                text = self.texts[path]
                self.assertIn("no autoriza la siguiente escena", text)
                self.assertIn("autorizacion explicita para iniciar el siguiente capitulo", text)
                self.assertNotIn("si quedan capitulos, vuelve a 2.1", text)
                self.assertNotIn("si quedan capitulos → volver a 2.1", text)
        self.assertIn("no vuelvas a 2.1 automaticamente",
                      self.texts[".opencode/agents/director.md"])

    def test_commands_stop_for_human_validation(self):
        for name in ("generar", "revisar", "expandir"):
            with self.subTest(command=name):
                text = self.texts[f".opencode/commands/{name}.md"]
                self.assertIn("checkpoint obligatorio de narrativa", text)
                self.assertIn("escena completa", text)
                self.assertRegex(text, r"esper[ae] (?:conformidad|confirmacion) explicita")
                self.assertNotIn("avanza secuencialmente por las fases hasta completar", text)
        for name in ("revisar", "expandir"):
            self.assertIn("cualquier cambio textual invalida la conformidad anterior",
                          self.texts[f".opencode/commands/{name}.md"])

    def test_validation_skills_preserve_execution_freedom(self):
        tone = self.texts[".opencode/skills/validacion-tono/SKILL.md"]
        self.assertNotIn("los personajes reaccionan acorde al tono", tone)
        self.assertIn("sin imponer conducta", tone)
        coherence = self.texts[".opencode/skills/validacion-coherencia/SKILL.md"]
        self.assertIn("la ausencia de una anotacion no demuestra una contradiccion", coherence)
        self.assertIn("`props` es opcional", coherence)
        self.assertIn("contradiccion material", coherence)
        self.assertNotIn("objeto no declarado en `[props:]`", coherence)
        for text in (tone, coherence):
            self.assertNotIn("**< 7**", text)
            self.assertIn("hash", text)
            self.assertIn("respeta el contrato del consumidor", text)
            self.assertIn("sin exigir un hash de candidata inexistente", text)


if __name__ == "__main__":
    unittest.main()
