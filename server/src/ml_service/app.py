from litestar import Litestar, get, post
from litestar.config.cors import CORSConfig
from litestar.exceptions import HTTPException
from litestar.openapi.config import OpenAPIConfig
from litestar.openapi.plugins import SwaggerRenderPlugin
from litestar.status_codes import HTTP_503_SERVICE_UNAVAILABLE

from .schemas import (
    AbandonmentRequest,
    AbandonmentResponse,
    AdherenceRequest,
    AdherenceResponse,
    HealthResponse,
)
from .service import ml_service


@get(
    "/health",
    summary="Health Check",
    description="Returns health status and model load states",
)
async def health() -> HealthResponse:
    return ml_service.get_health()


@post(
    "/predict/adherence",
    summary="Predict Medication Adherence Risk",
    description="Evaluates patient adherence risk profile based on clinical & cost features",
)
async def predict_adherence(data: AdherenceRequest) -> AdherenceResponse:
    try:
        return ml_service.predict_adherence(data)
    except RuntimeError as e:
        raise HTTPException(
            detail=str(e),
            status_code=HTTP_503_SERVICE_UNAVAILABLE,
        ) from e


@post(
    "/predict/abandonment",
    summary="Predict Prescription Abandonment",
    description="Evaluates probability of a patient abandoning a prescribed drug at pharmacy",
)
async def predict_abandonment(data: AbandonmentRequest) -> AbandonmentResponse:
    try:
        return ml_service.predict_abandonment(data)
    except RuntimeError as e:
        raise HTTPException(
            detail=str(e),
            status_code=HTTP_503_SERVICE_UNAVAILABLE,
        ) from e


# Enable CORS so frontend/client and microservices can call this directly
cors_config = CORSConfig(
    allow_origins=["*"],
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)

# Configure OpenAPI / Swagger documentation
openapi_config = OpenAPIConfig(
    title="CTS-NPN ML Inference Service (Litestar)",
    version="1.0.0",
    description="High-performance ML inference microservice for Medication Adherence & Abandonment prediction deployed on AWS App Runner.",
    render_plugins=[SwaggerRenderPlugin(path="/docs")],
)

app = Litestar(
    route_handlers=[health, predict_adherence, predict_abandonment],
    cors_config=cors_config,
    openapi_config=openapi_config,
)
