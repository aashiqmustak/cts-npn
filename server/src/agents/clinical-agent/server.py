import importlib.util
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

router_path = _current / "app" / "router.py"
spec = importlib.util.spec_from_file_location("clinical_agent_app_router", router_path)
if spec is None or spec.loader is None:
    raise ImportError(f"Unable to load clinical router from {router_path}")
router_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(router_module)
clinical_router = router_module.router

app = FastAPI(
    title="Clinical Eligibility Agent Service",
    description="Standalone clinical safety and eligibility evaluation service",
    version="1.0.0",
)

app.include_router(clinical_router)


@app.get("/")
async def root():
    return {
        "service": "Clinical Eligibility Agent API",
        "status": "online",
        "docs_url": "/docs",
    }


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8003)
