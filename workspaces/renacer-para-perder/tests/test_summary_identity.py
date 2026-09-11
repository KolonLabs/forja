"""NAR-004: identidad canonica de summaries. Solo backend/embeddings simulados.

python -B -m unittest discover -s tests -p test_summary_identity.py -v
"""

import argparse
from contextlib import redirect_stderr, redirect_stdout
from copy import deepcopy
import importlib.util
import io
import json
from pathlib import Path
import unittest
from unittest.mock import patch


SPEC = importlib.util.spec_from_file_location(
    "summary_identity_qdrant", Path(__file__).resolve().parents[1] / "scripts" / "qdrant.py"
)
helper = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(helper)


class SummaryIdentityTests(unittest.TestCase):
    def setUp(self):
        self.points = {}
        self.reads = []
        self.writes = []
        self.embedding = patch.object(helper, "embed", return_value=[0.25, 0.5]).start()
        patch.object(helper, "qdrant", side_effect=self.api).start()
        self.addCleanup(patch.stopall)

    def args(self, **changes):
        values = dict(proyecto="prueba", nivel="L1", id="a1b2c3d4",
                      parent_id="b2c3d4e5", seq=1, hilo=None,
                      texto="Resumen de una visita a la biblioteca.", texto_file=None,
                      fichas=None, fichas_file=None)
        values.update(changes)
        return argparse.Namespace(**values)

    def seed(self, sid="a1b2c3d4", physical=None, **changes):
        payload = dict(proyecto="prueba", stable_id=sid, nivel="L1", seq=1,
                       parent_id=helper.make_point_id("b2c3d4e5"),
                       texto="Resumen anterior.", fichas=["referencia-preexistente"],
                       extra={"version": 3})
        payload.update(changes)
        point = dict(id=physical or helper.make_point_id(sid), payload=payload,
                     vector=[0.75, 0.125])
        self.points[point["id"]] = point
        return point

    def api(self, method, path, data):
        # Cualquier operacion inesperada falla: nunca se llama a la red real.
        if method == "POST" and path == "/collections/summaries/points/scroll":
            self.reads.append((path, deepcopy(data)))
            matches = []
            for point in self.points.values():
                if all(point["payload"].get(term["key"]) == term["match"]["value"]
                       for term in data["filter"]["must"]):
                    matches.append(deepcopy(point))
            return {"status": "ok", "result": {"points": matches, "next_page_offset": None}}
        if method == "POST" and path == "/collections/summaries/points":
            self.reads.append((path, deepcopy(data)))
            return {"status": "ok", "result": [deepcopy(self.points[pid])
                    for pid in data["ids"] if pid in self.points]}
        if method == "PUT" and path == "/collections/summaries/points?wait=true":
            self.writes.append((path, deepcopy(data)))
            for point in data["points"]:
                self.points[point["id"]] = deepcopy(point)
            return {"status": "ok", "result": {"status": "completed"}}
        if method == "POST" and path == "/collections/summaries/points/payload?wait=true":
            self.writes.append((path, deepcopy(data)))
            for pid in data["points"]:
                self.points[pid]["payload"].update(deepcopy(data["payload"]))
            return {"status": "ok", "result": {"status": "completed"}}
        self.fail(f"Operacion no simulada: {method} {path}")

    def invoke(self, args=None, positional=False):
        output = io.StringIO()
        with redirect_stdout(output), redirect_stderr(io.StringIO()):
            (helper.cmd_upsert_summary_by_position if positional else helper.cmd_upsert_summary)(
                args or self.args())
        return output.getvalue()

    def rejected_without_writes(self, args=None, positional=False):
        snapshot = deepcopy(self.points)
        with self.assertRaises(SystemExit):
            self.invoke(args, positional)
        self.assertEqual(self.points, snapshot)
        self.assertEqual(self.writes, [])
        self.embedding.assert_not_called()

    def test_create_canonical_and_repeat_is_no_op(self):
        self.invoke()
        point = self.points[helper.make_point_id("a1b2c3d4")]
        self.assertEqual(point["payload"]["stable_id"], "a1b2c3d4")
        self.assertEqual(point["payload"]["parent_id"], helper.make_point_id("b2c3d4e5"))
        self.assertIn("unchanged", self.invoke())
        self.assertEqual(len(self.points), 1)
        self.assertEqual(len(self.writes), 1)
        self.embedding.assert_called_once()

    def test_update_preserves_metadata_and_fichas(self):
        original = deepcopy(self.seed())
        self.invoke()
        current = self.points[original["id"]]
        self.assertEqual(current["payload"], dict(original["payload"], texto=self.args().texto))
        self.assertEqual(current["vector"], [0.25, 0.5])

    def test_fichas_only_update_does_not_embed(self):
        original = deepcopy(self.seed(texto=self.args().texto))
        self.invoke(self.args(fichas="[]"))
        current = self.points[original["id"]]
        self.assertEqual(current["payload"]["fichas"], [])
        self.assertEqual(current["vector"], original["vector"])
        self.embedding.assert_not_called()

    def test_divergent_position_rejected_before_embed_or_write(self):
        self.seed(sid="c3d4e5f6")
        self.rejected_without_writes()

    def test_duplicate_position_rejected_even_when_canonical_exists(self):
        self.seed()
        self.seed(sid="c3d4e5f6")
        self.rejected_without_writes()

    def test_cross_project_physical_id_collision_rejected(self):
        self.seed(proyecto="otro-proyecto")
        self.rejected_without_writes()

    def test_point_without_identity_metadata_is_not_overwritten(self):
        point = self.seed()
        point["payload"] = {}
        self.rejected_without_writes()

    def test_identity_retrieve_failure_is_not_treated_as_absence(self):
        api = self.api

        def invalid(method, path, data):
            if path == "/collections/summaries/points":
                return {"status": "error", "result": []}
            return api(method, path, data)

        with patch.object(helper, "qdrant", side_effect=invalid):
            self.rejected_without_writes()

    def test_same_identity_cannot_move_or_change_level_or_thread(self):
        for change in (dict(seq=2), dict(parent_id="otro-padre"),
                       dict(nivel="L2"), dict(hilo="otro-hilo"), dict(seq=True)):
            with self.subTest(change=change):
                self.points.clear()
                self.seed(**change)
                self.rejected_without_writes()

    def test_noncanonical_physical_point_is_not_duplicated(self):
        self.seed(physical=helper.make_point_id("c3d4e5f6"))
        self.rejected_without_writes()

    def test_missing_identity_parent_or_seq_rejected(self):
        for change in (dict(id=None), dict(parent_id=None), dict(seq=None),
                       dict(seq=0), dict(seq=-1), dict(seq=True)):
            with self.subTest(change=change):
                self.rejected_without_writes(self.args(**change))

    def test_positional_create_L1_without_canonical_id_rejected(self):
        self.rejected_without_writes(self.args(id=None), positional=True)

    def test_positional_with_expected_id_creates_canonical(self):
        self.invoke(positional=True)
        self.assertEqual(set(self.points), {helper.make_point_id(self.args().id)})

    def test_positional_expected_id_mismatch_rejected(self):
        self.seed(sid="c3d4e5f6")
        self.rejected_without_writes(positional=True)

    def test_positional_existing_identity_reused_and_vector_updated(self):
        original = deepcopy(self.seed())
        self.invoke(self.args(id=None), positional=True)
        current = self.points[original["id"]]
        self.assertEqual(current["payload"]["stable_id"], "a1b2c3d4")
        self.assertEqual(current["payload"]["extra"], original["payload"]["extra"])
        self.assertEqual(current["payload"]["fichas"], original["payload"]["fichas"])
        self.assertEqual(current["vector"], [0.25, 0.5])
        self.assertEqual(current["payload"]["texto"], self.args().texto)
        self.assertIn("unchanged", self.invoke(self.args(id=None), positional=True))
        self.embedding.assert_called_once()

    def test_positional_duplicate_rejected_before_write(self):
        self.seed()
        self.seed(sid="c3d4e5f6")
        self.rejected_without_writes(self.args(id=None), positional=True)

    def test_new_L2_L3_can_allocate_without_known_identity(self):
        for level in ("L2", "L3"):
            with self.subTest(level=level):
                self.points.clear()
                self.invoke(self.args(id=None, nivel=level), positional=True)
                point, = self.points.values()
                self.assertEqual(point["payload"]["nivel"], level)
                self.assertEqual(len(point["payload"]["stable_id"]), 8)

    def test_L4_still_uses_unique_root(self):
        args = self.args(id="ignored", nivel="L4", parent_id=None, seq=None)
        self.invoke(args)
        first, = self.points.values()
        self.assertEqual(first["payload"]["nivel"], "L4")
        self.assertEqual(first["payload"]["parent_id"], "")
        self.assertNotEqual(first["payload"]["stable_id"], "ignored")
        self.invoke(args)
        self.assertEqual(len(self.points), 1)

    def test_backend_error_preflight_leaves_data_untouched(self):
        with patch.object(helper, "qdrant", side_effect=SystemExit("sin conexion")):
            self.rejected_without_writes()

    def test_unconfirmed_write_is_not_reported_as_success(self):
        api = self.api

        def unconfirmed(method, path, data):
            if method == "PUT":
                return {"status": "ok", "result": {"status": "acknowledged"}}
            return api(method, path, data)

        with patch.object(helper, "qdrant", side_effect=unconfirmed):
            with self.assertRaisesRegex(SystemExit, "not confirmed"):
                self.invoke()

    def test_canonical_L1_resolves_beat_to_chapter(self):
        cap = self.seed(sid="b2c3d4e5", nivel="L2", parent_id=helper.make_point_id("d4e5f6a7"))
        self.invoke()
        api = self.api

        def search(method, path, data):
            if path == "/collections/beats/points/search":
                return {"result": [{"score": 0.99, "payload": {
                    "stable_id": "e5f6a7b8", "parent_id": helper.make_point_id("a1b2c3d4"),
                    "proyecto": "prueba"}}]}
            return api(method, path, data)

        args = argparse.Namespace(proyecto="prueba", text="Biblioteca", text_file=None,
                                  top_beats=5, min_score=0.4, top_chapters=3)
        output = io.StringIO()
        with patch.object(helper, "qdrant", side_effect=search), redirect_stdout(output):
            helper.cmd_query_chapters_by_beat(args)
        result = json.loads(output.getvalue())
        self.assertEqual(len(result), 1)
        self.assertEqual(result[0]["chapter_stable_id"], cap["payload"]["stable_id"])

    def test_cli_accepts_expected_identity_on_positional_command(self):
        argv = ["qdrant.py", "upsert-summary-by-position", "--proyecto", "prueba",
                "--nivel", "L1", "--id", "a1b2c3d4", "--parent-id", "b2c3d4e5",
                "--seq", "1", "--texto", "Biblioteca"]
        with patch("sys.argv", argv), redirect_stdout(io.StringIO()):
            helper.main()
        self.assertIn(helper.make_point_id("a1b2c3d4"), self.points)


if __name__ == "__main__":
    unittest.main()
