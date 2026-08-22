import pathlib
import sys

import uvicorn
from fastapi import FastAPI

_current = pathlib.Path(__file__).resolve()
_server_src = _current.parents[2]

if str(_server_src) not in sys.path:
    sys.path.insert(0, str(_server_src))

from agents.invoice_agent.app.router import router as invoice_router

app = FastAPI(
    title="PharmaAssist Invoice Agent",
    version="1.0.0",
    description="Generates alternative medicine cost invoices",
)

app.include_router(invoice_router)


@app.get("/")
def root():
    return {"service": "PharmaAssist Invoice Agent", "status": "running"}


if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8005)
