import pathlib
import sys

import uvicorn
from fastapi import FastAPI

_current = pathlib.Path(__file__).resolve()
_server_src = _current.parents[2]

if str(_server_src) not in sys.path:
    sys.path.insert(0, str(_server_src))

from agents.patient_history_agent.app.router import router as patient_history_router

app = FastAPI(
    title="Patient History Agent Service",
    description="Standalone microservice for retrieving patient medication history and adherence-related features",
    version="1.0.0",
)

app.include_router(patient_history_router)


@app.get("/")
async def root():
    return {
        "service": "Patient History Agent API",
        "status": "online",
        "docs_url": "/docs",
    }


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8003)