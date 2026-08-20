import pathlib
import sys

import uvicorn
from fastapi import FastAPI

# Ensure server/src is in sys.path
_current = pathlib.Path(__file__).resolve().parent
_server_src = _current.parents[1]
if str(_server_src) not in sys.path:
    sys.path.insert(0, str(_server_src))

from agents.pa_agent.app.router import router as pa_router

app = FastAPI(
    title="Prior Authorization (PA) Agent Service",
    description="Standalone microservice for evaluating prior-authorization criteria, submission readiness, missing information, and clinical evidence",
    version="1.0.0",
)

app.include_router(pa_router)


@app.get("/")
async def root():
    return {
        "service": "Prior Authorization (PA) Agent API",
        "status": "online",
        "docs_url": "/docs",
    }


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8002)
