from typing import Any

from .schemas import AlternativeDiscoveryInput, AlternativeDiscoveryOutput
from .service import AlternativeDiscoveryService


class AlternativeDiscoveryAgent:
    def __init__(self, service: AlternativeDiscoveryService):
        self.service = service

    def process_request(
        self, request: AlternativeDiscoveryInput
    ) -> AlternativeDiscoveryOutput:
        return self.service.discover_alternatives(request)

    def run(self, task: dict[str, Any] | AlternativeDiscoveryInput) -> dict[str, Any]:
        """Generic execution entrypoint for agentic orchestrators."""
        if isinstance(task, AlternativeDiscoveryInput):
            req = task
        else:
            req = AlternativeDiscoveryInput.model_validate(task)
        res = self.process_request(req)
        return res.model_dump()
