import importlib.util
from pathlib import Path

from agents.formulary_agent.app.router import (
    router as formulary_router,
)
from fastapi import FastAPI

ROOT = Path(__file__).resolve().parent
CLINICAL_ROUTER_PATH = ROOT / "agents" / "clinical-agent" / "app" / "router.py"

spec = importlib.util.spec_from_file_location("clinical_agent_app_router", CLINICAL_ROUTER_PATH)
if spec is None or spec.loader is None:
    raise ImportError(f"Unable to load clinical router from {CLINICAL_ROUTER_PATH}")

clinical_router_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(clinical_router_module)
clinical_router = clinical_router_module.router

app = FastAPI(
    title="CTS PharmaAssist",
    description="Clinical Therapy Support Agent Platform",
    version="1.0.0",
)


app.include_router(formulary_router)
app.include_router(clinical_router)


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
