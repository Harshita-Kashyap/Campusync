from __future__ import annotations

import math
import os
import shutil
import tempfile
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from dotenv import load_dotenv
from flask import Flask, abort, jsonify, request, send_from_directory
from flask_cors import CORS
from google import genai
from google.genai import types
from mysql.connector import Error as MySQLError
import mysql.connector
from pydantic import BaseModel
from werkzeug.exceptions import HTTPException
from werkzeug.utils import secure_filename

# The PDF evaluator (assignment scoring & plagiarism detection) is optional so the
# water endpoints still start when pdf_evaluator.py is missing or its deps are not installed.
try:
    import pdf_evaluator as evaluator
except ImportError as _evaluator_error:  # pragma: no cover
    evaluator = None
    _EVALUATOR_IMPORT_ERROR = str(_evaluator_error)
else:
    _EVALUATOR_IMPORT_ERROR = ""

BASE_DIR = Path(__file__).resolve().parent
load_dotenv(BASE_DIR / ".env")

VALID_STATUSES = {"open", "in_progress", "resolved", "dismissed"}
VALID_SEVERITIES = {"low", "medium", "high", "critical"}
VALID_ISSUE_TYPES = {"leaking_tap", "overflow", "pipe_leak", "other"}
ALLOWED_IMAGE_TYPES = {
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".png": "image/png",
    ".webp": "image/webp",
}
FALLBACK_ANALYSIS = {
    "severity": "critical",
    "estimatedLitresPerHour": 1500.0,
    "issueType": "pipe_leak",
    "description": (
        "High-pressure water is actively spraying from a damaged or failing "
        "pipe coupling. This is a demo fallback estimate, not a live measurement."
    ),
    "source": "fallback",
}


class LeakAnalysis(BaseModel):
    """Structured output expected from Gemini."""

    severity: str
    estimatedLitresPerHour: float
    issueType: str
    description: str


app = Flask(__name__)
app.config["MAX_CONTENT_LENGTH"] = int(os.getenv("MAX_UPLOAD_BYTES", str(10 * 1024 * 1024)))
app.config["UPLOAD_FOLDER"] = os.getenv("UPLOAD_FOLDER", str(BASE_DIR / "uploads"))
Path(app.config["UPLOAD_FOLDER"]).mkdir(parents=True, exist_ok=True)

TEMP_DIR = BASE_DIR / "temp_submissions"
Path(TEMP_DIR).mkdir(parents=True, exist_ok=True)

cors_origins = [origin.strip() for origin in os.getenv("CORS_ORIGINS", "*").split(",") if origin.strip()]
CORS(app, resources={r"/*": {"origins": cors_origins or "*"}})


def _db_connect():
    """Open one short-lived MySQL connection using backend/.env settings."""
    return mysql.connector.connect(
        host=os.getenv("DB_HOST", "127.0.0.1"),
        port=int(os.getenv("DB_PORT", "3306")),
        user=os.getenv("DB_USER", "root"),
        password=os.getenv("DB_PASSWORD", ""),
        database=os.getenv("DB_NAME", "campusync"),
        connection_timeout=8,
        autocommit=False,
    )


def _issue_type(value: Any) -> str:
    raw = str(value or "").strip().lower().replace("-", "_")
    if raw in VALID_ISSUE_TYPES:
        return raw
    if any(word in raw for word in ("tap", "faucet", "drip")):
        return "leaking_tap"
    if "overflow" in raw or "overfill" in raw:
        return "overflow"
    if any(word in raw for word in ("pipe", "coupling", "joint", "spray", "burst")):
        return "pipe_leak"
    return "other"


def _severity(value: Any, litres_per_hour: float) -> str:
    raw = str(value or "").strip().lower()
    if raw in VALID_SEVERITIES:
        return raw
    if litres_per_hour < 10:
        return "low"
    if litres_per_hour < 100:
        return "medium"
    if litres_per_hour < 500:
        return "high"
    return "critical"


def _normalize_analysis(payload: dict[str, Any], source: str) -> dict[str, Any]:
    try:
        rate = float(payload.get("estimatedLitresPerHour", 0))
    except (TypeError, ValueError):
        raise ValueError("The analysis did not return a numeric water-loss rate") from None
    if not math.isfinite(rate) or rate <= 0:
        raise ValueError("The analysis returned an invalid water-loss rate")
    description = str(payload.get("description", "")).strip()
    if not description:
        description = "Water leak identified; details should be confirmed by a person."
    return {
        "severity": _severity(payload.get("severity"), rate),
        "estimatedLitresPerHour": rate,
        "issueType": _issue_type(payload.get("issueType")),
        "description": description[:4000],
        "source": source,
    }


def analyze_leak_image(image_path: str | Path) -> dict[str, Any]:
    """Analyze a saved image with Gemini; use a visibly labelled demo fallback on errors."""
    try:
        api_key = os.getenv("GEMINI_API_KEY", "").strip()
        if not api_key:
            raise RuntimeError("GEMINI_API_KEY is not configured")

        path = Path(image_path)
        mime = ALLOWED_IMAGE_TYPES.get(path.suffix.lower(), "image/jpeg")
        image_part = types.Part.from_bytes(data=path.read_bytes(), mime_type=mime)

        client = genai.Client(
            api_key=api_key,
            http_options=types.HttpOptions(timeout=30_000),  # milliseconds
        )
        response = client.models.generate_content(
            model=os.getenv("GEMINI_MODEL", "gemini-2.5-flash"),
            contents=[
                image_part,
                (
                    "Analyze this water leak image. Estimate its severity, water loss "
                    "rate in litres per hour, issue type, and description. Use severity "
                    "low, medium, high, or critical. Use issueType leaking_tap, overflow, "
                    "pipe_leak, or other. If the image is not clearly a leak, explain the "
                    "uncertainty in the description and choose other. These are estimates, "
                    "not sensor measurements."
                ),
            ],
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=LeakAnalysis,
                temperature=0.2,
            ),
        )
        if not response.text:
            raise ValueError("Gemini returned an empty response")
        parsed = LeakAnalysis.model_validate_json(response.text)
        return _normalize_analysis(parsed.model_dump(), "ai")
    except Exception as exc:
        app.logger.warning("Leak image analysis failed; using labelled demo fallback: %s", exc)
        return dict(FALLBACK_ANALYSIS)


def _required_text(value: Any, field_name: str, max_length: int = 255) -> str:
    result = str(value or "").strip()
    if not result:
        abort(400, description=f"{field_name} is required")
    if len(result) > max_length:
        abort(400, description=f"{field_name} must be at most {max_length} characters")
    return result


def _number(value: Any, field_name: str, *, minimum: float = 0, maximum: float | None = None) -> float:
    try:
        result = float(value)
    except (TypeError, ValueError):
        abort(400, description=f"{field_name} must be a number")
    if not math.isfinite(result) or result < minimum or (maximum is not None and result > maximum):
        limit = f" between {minimum} and {maximum}" if maximum is not None else f" at least {minimum}"
        abort(400, description=f"{field_name} must be{limit}")
    return result


def _image_file() -> tuple[str, Path] | None:
    upload = request.files.get("image")
    if upload is None or not upload.filename:
        return None

    safe_name = secure_filename(upload.filename)
    suffix = Path(safe_name).suffix.lower()
    if suffix not in ALLOWED_IMAGE_TYPES:
        abort(415, description="Upload a JPG, PNG, or WebP image")
    content_type = (upload.mimetype or "").lower()
    expected_type = ALLOWED_IMAGE_TYPES[suffix]
    if content_type and content_type not in {expected_type, "application/octet-stream"}:
        abort(415, description=f"Image content type must match {suffix}")

    stored_name = f"{uuid.uuid4().hex}{suffix}"
    stored_path = Path(app.config["UPLOAD_FOLDER"]) / stored_name
    upload.save(stored_path)
    return stored_name, stored_path


def _iso_utc(value: datetime) -> str:
    if value.tzinfo is None:
        value = value.replace(tzinfo=timezone.utc)
    else:
        value = value.astimezone(timezone.utc)
    return value.isoformat().replace("+00:00", "Z")


def _serialize_row(row: dict[str, Any]) -> dict[str, Any]:
    image_url = None
    if row.get("image_filename"):
        image_url = f"/api/water/incidents/{row['id']}/image"
    return {
        "id": str(row["id"]),
        "locationName": row["location_name"],
        "issueType": row["issue_type"],
        "estimatedLitresPerHour": float(row["estimated_litres_per_hour"]),
        "reportedAt": _iso_utc(row["reported_at"]),
        "estimatedDurationHours": float(row["estimated_duration_hours"]),
        "severity": row["severity"],
        "description": row["description"],
        "status": row["status"],
        "source": row.get("analysis_source") or "manual",
        "imageUrl": image_url,
    }


def _make_incident_json(
    incident_id: str,
    location: str,
    result: dict[str, Any],
    reported_at: datetime,
    duration_hours: float,
    image_name: str | None,
) -> dict[str, Any]:
    return {
        "id": incident_id,
        "locationName": location,
        "issueType": result["issueType"],
        "estimatedLitresPerHour": float(result["estimatedLitresPerHour"]),
        "reportedAt": _iso_utc(reported_at),
        "estimatedDurationHours": duration_hours,
        "severity": result["severity"],
        "description": result["description"],
        "status": "open",
        "source": result["source"],
        "imageUrl": f"/api/water/incidents/{incident_id}/image" if image_name else None,
    }


@app.get("/health")
def health():
    """Simple API + database readiness check."""
    connection = None
    cursor = None
    try:
        connection = _db_connect()
        cursor = connection.cursor()
        cursor.execute("SELECT COUNT(*) FROM water_incidents")
        cursor.fetchone()
        return jsonify(status="ok", database="connected", schema="ready"), 200
    except MySQLError:
        app.logger.exception("MySQL health check failed")
        return jsonify(status="error", database="unavailable"), 503
    finally:
        if cursor is not None:
            cursor.close()
        if connection is not None and connection.is_connected():
            connection.close()


@app.post("/analyze")
def analyze_endpoint():
    """Compatibility endpoint: upload image and return analysis without storing an incident."""
    saved = _image_file()
    if saved is None:
        abort(400, description="Multipart field 'image' is required")
    _, image_path = saved
    try:
        return jsonify(analyze_leak_image(image_path)), 200
    finally:
        image_path.unlink(missing_ok=True)


# ==========================================
# Campusync Assignment Evaluator Endpoints
# ==========================================

DEFAULT_SUBJECTS = ["DBMS"]


def _require_evaluator():
    if evaluator is None:
        abort(503, description=f"Assignment evaluator is not available: {_EVALUATOR_IMPORT_ERROR or 'pdf_evaluator not installed'}")


def _json_safe(value: Any) -> Any:
    """Turn NaN/inf/numpy/pandas values into plain JSON (Dart's jsonDecode rejects NaN)."""
    if isinstance(value, dict):
        return {str(k): _json_safe(v) for k, v in value.items()}
    if isinstance(value, (list, tuple, set)):
        return [_json_safe(v) for v in value]
    if hasattr(value, "item") and not isinstance(value, (str, bytes)):
        try:
            value = value.item()
        except Exception:
            value = str(value)
    if isinstance(value, float) and not math.isfinite(value):
        return None
    if isinstance(value, datetime):
        return _iso_utc(value)
    if value is None or isinstance(value, (str, int, float, bool)):
        return value
    return str(value)


def _pick(record: dict[str, Any], *names: str) -> Any:
    """Case/space-insensitive lookup of the first present column."""
    lowered = {str(k).strip().lower().replace(" ", "_"): v for k, v in record.items()}
    for name in names:
        value = lowered.get(name)
        if value is not None and value != "":
            return value
    return None


def _to_float(value: Any, default: float | None = None) -> float | None:
    try:
        number = float(value)
    except (TypeError, ValueError):
        return default
    return number if math.isfinite(number) else default


def _normalize_evaluation(record: dict[str, Any]) -> dict[str, Any]:
    """Stable contract for the Flutter app. The untouched row is kept under "raw".

    If your pdf_evaluator uses different column names, add them to the lists below.
    """
    file_name = _pick(record, "file_name", "filename", "file", "student", "student_name", "submission", "name", "index")
    score = _to_float(_pick(record, "score", "total_score", "final_score", "marks", "total", "grade"), 0.0)
    max_score = _to_float(_pick(record, "max_score", "out_of", "max_marks", "maximum"), None)
    if max_score is None or max_score <= 0:
        max_score = 100.0 if score is not None and score > 10 else 10.0
    plagiarism = _to_float(
        _pick(record, "plagiarism_score", "plagiarism", "similarity", "max_similarity", "similarity_score", "plagiarism_percent", "plagiarism_%"), None
    )
    flagged_raw = _pick(record, "plagiarism_flag", "flagged", "is_plagiarised", "is_plagiarized", "duplicate", "duplicate_detected")
    if isinstance(flagged_raw, str):
        flagged = flagged_raw.strip().lower() in {"1", "true", "yes", "y", "flagged", "high"}
    elif flagged_raw is not None:
        flagged = bool(flagged_raw)
    else:
        flagged = bool(plagiarism is not None and (plagiarism >= 70 if plagiarism > 1 else plagiarism >= 0.7))
    feedback = _pick(record, "feedback", "constructive_feedback", "comments", "summary", "remarks")
    errors = _pick(record, "errors", "error_diagnosis", "diagnosis", "mistakes")
    pages = _to_float(_pick(record, "pages", "page_count", "num_pages"), None)
    return {
        "fileName": str(file_name or "submission.pdf"),
        "score": score,
        "maxScore": max_score,
        "feedback": str(feedback or "").strip(),
        "errors": str(errors).strip() if errors is not None else "",
        "plagiarismScore": plagiarism,
        "plagiarismFlagged": flagged,
        "pages": int(pages) if pages is not None else None,
        "raw": record,
    }


@app.get("/api/subjects")
def get_subjects():
    """Return available subject rubrics for assignment evaluation."""
    if evaluator is None:
        return jsonify({"subjects": DEFAULT_SUBJECTS, "evaluatorAvailable": False})
    return jsonify({"subjects": list(evaluator.SUBJECT_RUBRICS.keys()), "evaluatorAvailable": True})


@app.post("/api/evaluate")
def evaluate_assignments():
    """
    Accepts one or more student PDF files and returns AI scores, feedback,
    error diagnoses and plagiarism metrics. Each request uses its own temp
    folder, so concurrent uploads cannot overwrite or delete each other.
    """
    _require_evaluator()
    files = request.files.getlist("files")
    if not files or all(f.filename == "" for f in files):
        abort(400, description="No files uploaded. Send PDFs in the multipart field 'files'.")

    subject = request.form.get("subject", "DBMS")
    if subject not in evaluator.SUBJECT_RUBRICS:
        abort(400, description=f"Unknown subject '{subject}'. Choose one of: {', '.join(evaluator.SUBJECT_RUBRICS)}")
    model = request.form.get("model", evaluator.DEFAULT_MODEL)
    api_key = request.form.get("api_key", None)
    key_to_use = api_key.strip() if (api_key and api_key.strip()) else evaluator.DEFAULT_API_KEY

    work_dir = Path(tempfile.mkdtemp(prefix="eval_", dir=TEMP_DIR))
    try:
        saved_count = 0
        seen: set[str] = set()
        for upload in files:
            if not upload.filename or not upload.filename.lower().endswith(".pdf"):
                continue
            name = secure_filename(upload.filename) or f"submission_{saved_count + 1}.pdf"
            if name in seen:
                name = f"{saved_count + 1}_{name}"
            seen.add(name)
            upload.save(work_dir / name)
            saved_count += 1

        if saved_count == 0:
            abort(400, description="No valid PDF files were provided.")

        try:
            df = evaluator.run_evaluation(
                submissions_dir=str(work_dir),
                subject=subject,
                model=model,
                api_key=key_to_use,
                output_csv=str(work_dir / "results.csv"),
            )
        except Exception as exc:
            app.logger.exception("Assignment evaluation failed")
            abort(502, description=f"Evaluation failed: {exc}")

        if df is None or df.empty:
            abort(502, description="No evaluation results were generated.")

        records = _json_safe(df.reset_index().to_dict(orient="records"))
    finally:
        shutil.rmtree(work_dir, ignore_errors=True)

    results = [_normalize_evaluation(record) for record in records]
    return jsonify(
        status="success",
        total_evaluated=len(results),
        subject=subject,
        model=model,
        results=results,
    )


# ==========================================
# Water Incident Endpoints
# ==========================================

@app.post("/api/water/incidents")
def create_incident():
    """Analyze an uploaded photo (or accept a manual report) and persist the incident in MySQL."""
    payload: Any = request.form if request.form else (request.get_json(silent=True) or {})
    if not isinstance(payload, dict) and not hasattr(payload, "get"):
        abort(400, description="Request body must be multipart form data or JSON")

    location = _required_text(payload.get("location") or payload.get("locationName"), "Location")
    duration_hours = _number(
        payload.get("estimatedDurationHours", payload.get("durationHours", 0)),
        "estimatedDurationHours",
        minimum=0,
        maximum=8760,
    )
    reporter_note = str(payload.get("reporterNote") or "").strip()
    if len(reporter_note) > 1000:
        abort(400, description="Reporter note must be at most 1000 characters")

    saved_image: tuple[str, Path] | None = _image_file()
    image_name: str | None = saved_image[0] if saved_image else None
    image_path: Path | None = saved_image[1] if saved_image else None

    if image_path is not None:
        result = analyze_leak_image(image_path)
        if reporter_note:
            result["description"] = f"{result['description']} Reporter note: {reporter_note}"[:4000]
    else:
        issue_type = str(payload.get("issueType") or "").strip().lower()
        severity = str(payload.get("severity") or "").strip().lower()
        if issue_type not in VALID_ISSUE_TYPES:
            abort(400, description=f"issueType must be one of: {', '.join(sorted(VALID_ISSUE_TYPES))}")
        if severity not in VALID_SEVERITIES:
            abort(400, description=f"severity must be one of: {', '.join(sorted(VALID_SEVERITIES))}")
        rate = _number(payload.get("estimatedLitresPerHour"), "estimatedLitresPerHour", minimum=0.000001)
        description = _required_text(payload.get("description"), "Description", max_length=4000)
        result = {
            "issueType": issue_type,
            "severity": severity,
            "estimatedLitresPerHour": rate,
            "description": description,
            "source": "manual",
        }

    incident_id = str(uuid.uuid4())
    reported_at = datetime.now(timezone.utc)
    stored_datetime = reported_at.replace(tzinfo=None)
    connection = None
    cursor = None
    try:
        connection = _db_connect()
        cursor = connection.cursor()
        cursor.execute(
            """
            INSERT INTO water_incidents (
                id, location_name, issue_type, estimated_litres_per_hour,
                reported_at, estimated_duration_hours, severity, description,
                status, analysis_source, image_filename
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, 'open', %s, %s)
            """,
            (
                incident_id,
                location,
                result["issueType"],
                result["estimatedLitresPerHour"],
                stored_datetime,
                duration_hours,
                result["severity"],
                result["description"],
                result["source"],
                image_name,
            ),
        )
        connection.commit()
    except Exception:
        if connection is not None:
            connection.rollback()
        if image_path is not None:
            image_path.unlink(missing_ok=True)
        raise
    finally:
        if cursor is not None:
            cursor.close()
        if connection is not None and connection.is_connected():
            connection.close()

    incident = _make_incident_json(incident_id, location, result, reported_at, duration_hours, image_name)
    return jsonify(message="Water incident saved", incident=incident), 201


@app.get("/api/water/incidents")
def list_incidents():
    """Return all persisted water incidents, newest first."""
    connection = _db_connect()
    cursor = None
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT id, location_name, issue_type, estimated_litres_per_hour,
                   reported_at, estimated_duration_hours, severity, description,
                   status, analysis_source, image_filename
            FROM water_incidents
            ORDER BY reported_at DESC
            """
        )
        incidents = [_serialize_row(row) for row in cursor.fetchall()]
        return jsonify(incidents=incidents, count=len(incidents)), 200
    finally:
        if cursor is not None:
            cursor.close()
        if connection.is_connected():
            connection.close()


@app.patch("/api/water/incidents/<incident_id>/status")
def update_incident_status(incident_id: str):
    """Update the repair workflow status for an existing incident."""
    payload = request.get_json(silent=True) or {}
    status = str(payload.get("status") or "").strip().lower()
    if status not in VALID_STATUSES:
        abort(400, description=f"status must be one of: {', '.join(sorted(VALID_STATUSES))}")

    connection = _db_connect()
    cursor = None
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute(
            "UPDATE water_incidents SET status = %s WHERE id = %s",
            (status, incident_id),
        )
        cursor.execute(
            """
            SELECT id, location_name, issue_type, estimated_litres_per_hour,
                   reported_at, estimated_duration_hours, severity, description,
                   status, analysis_source, image_filename
            FROM water_incidents WHERE id = %s
            """,
            (incident_id,),
        )
        row = cursor.fetchone()
        if row is None:
            connection.rollback()
            abort(404, description="Water incident was not found")
        connection.commit()
        return jsonify(message="Water incident status updated", incident=_serialize_row(row)), 200
    finally:
        if cursor is not None:
            cursor.close()
        if connection.is_connected():
            connection.close()


@app.get("/api/water/incidents/<incident_id>/image")
def get_incident_image(incident_id: str):
    """Serve the image attached to a saved incident, if one exists."""
    connection = _db_connect()
    cursor = None
    try:
        cursor = connection.cursor()
        cursor.execute("SELECT image_filename FROM water_incidents WHERE id = %s", (incident_id,))
        row = cursor.fetchone()
        if row is None or not row[0]:
            abort(404, description="No image is stored for this incident")
        return send_from_directory(app.config["UPLOAD_FOLDER"], row[0], conditional=True)
    finally:
        if cursor is not None:
            cursor.close()
        if connection.is_connected():
            connection.close()


@app.errorhandler(HTTPException)
def handle_http_error(error: HTTPException):
    return jsonify(error=error.name.lower().replace(" ", "_"), message=error.description), error.code


@app.errorhandler(MySQLError)
def handle_mysql_error(error: MySQLError):
    app.logger.exception("MySQL request failed")
    return jsonify(error="database_unavailable", message="The MySQL database is unavailable or not configured."), 503


@app.errorhandler(Exception)
def handle_unexpected_error(error: Exception):
    app.logger.exception("Unhandled API error")
    return jsonify(error="internal_error", message="The server could not complete the request."), 500


if __name__ == "__main__":
    app.run(
        host=os.getenv("HOST", "0.0.0.0"),
        port=int(os.getenv("PORT", "5000")),
        debug=os.getenv("FLASK_DEBUG", "false").lower() == "true",
    )