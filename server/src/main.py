from agents.formulary_agent.app.router import (
    router as formulary_router,
)
from fastapi import FastAPI

app = FastAPI(
    title="CTS PharmaAssist",
    description="Clinical Therapy Support Agent Platform",
    version="1.0.0",
)


app.include_router(formulary_router)


@app.get("/")
async def root():
    return {
        "service": "CTS PharmaAssist",
        "status": "running",
    }


@app.get("/health")
async def health():
    return {
        "status": "healthy",
    }
