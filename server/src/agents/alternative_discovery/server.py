import pathlib
import sys

import uvicorn
from dotenv import load_dotenv
from fastapi import FastAPI

# Load environment variables from .env file
load_dotenv()

# Ensure server/src is in sys.path
_current = pathlib.Path(__file__).resolve().parent
_server_src = _current.parents[1]
if str(_server_src) not in sys.path:
    sys.path.insert(0, str(_server_src))

from agents.alternative_discovery.app.router import router as alt_router

app = FastAPI(title="Alternative Discovery Service", version="1.0.0")
app.include_router(alt_router)


@app.get("/")
async def root():
    return {"service": "Alternative Discovery Agent API", "status": "online"}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8004)
