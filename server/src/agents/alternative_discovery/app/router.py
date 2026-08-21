from fastapi import APIRouter, HTTPException

from .agent import AlternativeDiscoveryAgent
from .repository import AlternativeDiscoveryRepository
from .schemas import AlternativeDiscoveryInput, AlternativeDiscoveryOutput
from .service import AlternativeDiscoveryService

router = APIRouter(prefix="/alternative-discovery", tags=["Alternative Discovery Agent"])

repository = AlternativeDiscoveryRepository()
service = AlternativeDiscoveryService(repository)
agent = AlternativeDiscoveryAgent(service)

@router.get("/health")
def health():
    return {"status": "healthy", "agent": "alternative_discovery", "dataset_records": len(repository.records)}

@router.post("/discover", response_model=AlternativeDiscoveryOutput)
def discover(request: AlternativeDiscoveryInput) -> AlternativeDiscoveryOutput:
    try:
        return agent.process_request(request)
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=500, detail=f"Internal Agent Error: {exc}")
