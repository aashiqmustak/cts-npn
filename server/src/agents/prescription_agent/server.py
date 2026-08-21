"""Local HTTP server for the standalone prescription agent."""

import argparse
import importlib
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Any

process_prescription = importlib.import_module("app.router").process_prescription


class PrescriptionRequestHandler(BaseHTTPRequestHandler):
    def do_GET(self) -> None:
        if self.path == "/":
            self._send_html()
            return
        if self.path == "/health":
            self._send_json({"status": "ok", "agent": "prescription_agent"}, 200)
            return
        self._send_json({"detail": "Not found"}, 404)

    def do_POST(self) -> None:
        if self.path != "/normalize-prescription":
            self._send_json({"detail": "Not found"}, 404)
            return

        try:
            content_length = int(self.headers.get("Content-Length", "0"))
            payload: dict[str, Any] = json.loads(self.rfile.read(content_length))
            result = process_prescription(
                patient_id=payload.get("patient_id", ""),
                prescription_text=payload.get("prescription_text", ""),
                doctor_id=payload.get("doctor_id", ""),
                prescription_id=payload.get("prescription_id"),
            )
        except json.JSONDecodeError:
            self._send_json({"detail": "Request body must be valid JSON"}, 400)
            return
        except (TypeError, ValueError) as error:
            self._send_json({"detail": str(error)}, 400)
            return

        self._send_json(result.model_dump(), 200)

    def _send_json(self, body: dict[str, Any], status_code: int) -> None:
        encoded_body = json.dumps(body, indent=2).encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(encoded_body)))
        self.end_headers()
        self.wfile.write(encoded_body)

    def _send_html(self) -> None:
        html = """<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Prescription Agent</title>
    <style>
        body { max-width: 760px; margin: 40px auto; padding: 0 20px; font: 16px system-ui, sans-serif; }
        label { display: block; margin-top: 16px; font-weight: 600; }
        input, textarea, button { box-sizing: border-box; width: 100%; margin-top: 6px; padding: 10px; font: inherit; }
        textarea { min-height: 100px; }
        button { margin-top: 20px; cursor: pointer; }
        pre { overflow: auto; padding: 16px; background: #f1f3f5; }
    </style>
</head>
<body>
    <h1>Prescription Agent</h1>
    <form id="prescription-form">
        <label>Patient ID<input id="patient_id" required value="PAT_001"></label>
        <label>Doctor ID<input id="doctor_id" required value="DOC_001"></label>
        <label>Prescription text<textarea id="prescription_text" required>Atorvastatin 20 mg once daily for 30 days</textarea></label>
        <button type="submit">Normalize prescription</button>
    </form>
    <h2>Result</h2>
    <pre id="result">Submit the form to see the normalized prescription.</pre>
    <script>
        document.getElementById('prescription-form').addEventListener('submit', async (event) => {
            event.preventDefault();
            const result = document.getElementById('result');
            const payload = {
                patient_id: document.getElementById('patient_id').value,
                doctor_id: document.getElementById('doctor_id').value,
                prescription_text: document.getElementById('prescription_text').value
            };
            const response = await fetch('/normalize-prescription', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify(payload)
            });
            result.textContent = JSON.stringify(await response.json(), null, 2);
        });
    </script>
</body>
</html>"""
        encoded_html = html.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(encoded_html)))
        self.end_headers()
        self.wfile.write(encoded_html)

    def log_message(self, format: str, *args: object) -> None:
        print(f"{self.address_string()} - {format % args}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Run the prescription agent HTTP server."
    )
    parser.add_argument("--host", default="127.0.0.1", help="Server host")
    parser.add_argument("--port", type=int, default=8000, help="Server port")
    args = parser.parse_args()

    server = ThreadingHTTPServer((args.host, args.port), PrescriptionRequestHandler)
    print(f"Prescription agent running at http://{args.host}:{args.port}")
    print("POST JSON to /normalize-prescription or GET /health")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping prescription agent")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
