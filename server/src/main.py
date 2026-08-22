# Forwarding wrapper to agent_service
import pathlib
import sys

_current = pathlib.Path(__file__).resolve().parent
if str(_current) not in sys.path:
    sys.path.insert(0, str(_current))

from agent_service import app, run_agent_service

if __name__ == "__main__":
    run_agent_service()
