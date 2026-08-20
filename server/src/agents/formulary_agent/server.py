import pathlib
import sys
import uvicorn
from fastapi import FastAPI

# Ensure server/src is in sys.path
_current = pathlib.Path(__file__).resolve().parent
_server_src = _current.parents[1]
if str(_server_src) not in sys.path:
    sys.path.insert(0, str(_server_src))

from agents.formulary_agent.app.router import router as formulary_router

app = FastAPI(
    title="Formulary Agent Standalone Service",
    description="Standalone microservice endpoint for Formulary lookup and tier verification",
    version="1.0.0",
)

app.include_router(formulary_router)


@app.get("/")
async def root():
    return {
        "service": "Formulary Agent API",
        "status": "online",
        "docs_url": "/docs",
    }


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8001)
