import pathlib
import sys

import uvicorn
from fastapi import FastAPI

_current = pathlib.Path(__file__).resolve().parent
_server_src = _current.parents[1]
if str(_server_src) not in sys.path:
    sys.path.insert(0, str(_server_src))
app_dir = _current / "app"
if str(app_dir) not in sys.path:
    sys.path.insert(0, str(app_dir))

from agents.ranking_agent.app.router import router as ranking_router

app = FastAPI(
    title="Ranking & Clinical Safety Agent Service",
    description="Multi-factor clinical safety evaluation, alternative candidate ranking, top-1 drug selection, and rejection explanation service",
    version="2.0.0",
)

app.include_router(ranking_router)


@app.get("/")
async def root():
    return {
        "service": "Ranking & Clinical Safety Agent API",
        "version": "2.0.0",
        "status": "online",
        "docs_url": "/docs",
        "endpoints": {
            "health": "/ranking-agent/health",
            "rank": "/ranking-agent/rank",
            "evaluate": "/ranking-agent/evaluate",
        },
    }


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8003)
