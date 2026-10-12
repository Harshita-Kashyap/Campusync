import io
import tempfile
import unittest
from datetime import datetime
from pathlib import Path
from unittest.mock import patch

import app as water_api


class FakeStore:
    def __init__(self):
        self.rows = {}

    def connect(self):
        return FakeConnection(self)


class FakeConnection:
    def __init__(self, store):
        self.store = store
        self.connected = True

    def cursor(self, dictionary=False):
        return FakeCursor(self.store, dictionary)

    def commit(self):
        pass

    def rollback(self):
        pass

    def is_connected(self):
        return self.connected

    def close(self):
        self.connected = False


class FakeCursor:
    def __init__(self, store, dictionary):
        self.store = store
        self.dictionary = dictionary
        self.one = None
        self.many = []

    def execute(self, query, params=None):
        statement = " ".join(query.lower().split())
        params = params or ()
        if statement.startswith("select count(*)"):
            self.one = (len(self.store.rows),)
        elif statement.startswith("insert into water_incidents"):
            row = {
                "id": params[0],
                "location_name": params[1],
                "issue_type": params[2],
                "estimated_litres_per_hour": params[3],
                "reported_at": params[4],
                "estimated_duration_hours": params[5],
                "severity": params[6],
                "description": params[7],
                "status": "open",
                "analysis_source": params[8],
                "image_filename": params[9],
            }
            self.store.rows[row["id"]] = row
        elif statement.startswith("update water_incidents"):
            status, incident_id = params
            if incident_id in self.store.rows:
                self.store.rows[incident_id]["status"] = status
        elif statement.startswith("select image_filename"):
            row = self.store.rows.get(params[0])
            self.one = (row["image_filename"],) if row else None
        elif "order by reported_at desc" in statement:
            rows = sorted(self.store.rows.values(), key=lambda row: row["reported_at"], reverse=True)
            self.many = [dict(row) for row in rows]
        elif "where id = %s" in statement:
            row = self.store.rows.get(params[0])
            self.one = dict(row) if row else None
        else:
            raise AssertionError(f"Unexpected SQL in test: {query}")

    def fetchone(self):
        return self.one

    def fetchall(self):
        return self.many

    def close(self):
        pass


class WaterApiTests(unittest.TestCase):
    def setUp(self):
        self.store = FakeStore()
        self.client = water_api.app.test_client()
        self.db_patch = patch.object(water_api, "_db_connect", side_effect=self.store.connect)
        self.db_patch.start()
        self.addCleanup(self.db_patch.stop)
        self.temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_dir.cleanup)
        self.old_upload_folder = water_api.app.config["UPLOAD_FOLDER"]
        water_api.app.config["UPLOAD_FOLDER"] = self.temp_dir.name
        self.addCleanup(setattr, water_api.app.config, "UPLOAD_FOLDER", self.old_upload_folder)

    def test_health_checks_database_and_schema(self):
        response = self.client.get("/health")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json()["schema"], "ready")

    def test_photo_report_is_analyzed_and_persisted(self):
        analysis = {
            "issueType": "pipe_leak",
            "severity": "critical",
            "estimatedLitresPerHour": 1500.0,
            "description": "Water spraying from a pipe coupling.",
            "source": "ai",
        }
        with patch.object(water_api, "analyze_leak_image", return_value=analysis):
            response = self.client.post(
                "/api/water/incidents",
                data={
                    "image": (io.BytesIO(b"fake-image"), "leak.jpg"),
                    "location": "Hostel B washroom",
                    "estimatedDurationHours": "2",
                },
                content_type="multipart/form-data",
            )
        self.assertEqual(response.status_code, 201)
        incident = response.get_json()["incident"]
        self.assertEqual(incident["source"], "ai")
        self.assertEqual(incident["estimatedLitresPerHour"], 1500.0)
        self.assertEqual(len(self.store.rows), 1)
        self.assertTrue((Path(self.temp_dir.name) / next(iter(self.store.rows.values()))["image_filename"]).exists())

    def test_manual_report_is_persisted_with_manual_source(self):
        response = self.client.post(
            "/api/water/incidents",
            data={
                "location": "Library washroom",
                "estimatedDurationHours": "1.5",
                "issueType": "leaking_tap",
                "severity": "low",
                "estimatedLitresPerHour": "5",
                "description": "Tap is dripping steadily",
            },
            content_type="multipart/form-data",
        )
        self.assertEqual(response.status_code, 201)
        incident = response.get_json()["incident"]
        self.assertEqual(incident["source"], "manual")
        self.assertIsNone(incident["imageUrl"])
        self.assertEqual(len(self.store.rows), 1)

    def test_list_and_status_endpoint(self):
        incident_id = "test-incident"
        self.store.rows[incident_id] = {
            "id": incident_id,
            "location_name": "Library",
            "issue_type": "leaking_tap",
            "estimated_litres_per_hour": 5.0,
            "reported_at": datetime(2026, 10, 12, 10, 0, 0),
            "estimated_duration_hours": 1.0,
            "severity": "low",
            "description": "Dripping tap",
            "status": "open",
            "analysis_source": "manual",
            "image_filename": None,
        }
        listed = self.client.get("/api/water/incidents")
        self.assertEqual(listed.status_code, 200)
        self.assertEqual(listed.get_json()["count"], 1)

        updated = self.client.patch(
            f"/api/water/incidents/{incident_id}/status",
            json={"status": "in_progress"},
        )
        self.assertEqual(updated.status_code, 200)
        self.assertEqual(updated.get_json()["incident"]["status"], "in_progress")

    def test_invalid_status_is_rejected(self):
        response = self.client.patch("/api/water/incidents/missing/status", json={"status": "working"})
        self.assertEqual(response.status_code, 400)
        self.assertIn("status", response.get_json()["message"])


if __name__ == "__main__":
    unittest.main()
