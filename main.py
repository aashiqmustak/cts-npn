# ruff: noqa: I001, F401
import argparse
import asyncio
import os
import sys
import threading
import uvicorn
from dotenv import load_dotenv

# Ensure root and server/src are in sys.path
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
SERVER_SRC_DIR = os.path.join(BASE_DIR, "server", "src")

if SERVER_SRC_DIR not in sys.path:
    sys.path.insert(0, SERVER_SRC_DIR)
if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)

# Load environment variables
load_dotenv()

# Import the unified Litestar Agent & Orchestrator API Service
from agent_service import app as agent_app

# Import Alternea Voice Bot at module level (required for Pipecat runner discovery)
try:
    from alternea_voice.features.rtc.bot import bot
except Exception as _bot_err:  # noqa: BLE001
    bot = None
    print(f"[Alternea Voice] Note: Voice bot import warning: {_bot_err}")


def start_agent_service(host: str = "0.0.0.0", port: int = 8000):
    """Runs the Litestar Agent & Orchestrator API Server."""
    print(f"\n[CTS PharmaAssist] Starting Litestar Agent API Service on http://{host}:{port}")
    print(f"[CTS PharmaAssist] Interactive OpenAPI Docs available at http://127.0.0.1:{port}/docs")
    print(
        f"[CTS PharmaAssist] Orchestrator Endpoint: http://127.0.0.1:{port}/api/v1/orchestrate/evaluate-prescription\n"
    )
    uvicorn.run(agent_app, host=host, port=port, log_level="info")


def start_voice_agent():
    """Runs the Alternea Voice Pipecat Agent."""
    try:
        from pipecat.runner.run import main as pipecat_main

        print("\n[Alternea Voice] Initializing Voice Agent Runner...")
        pipecat_main()
    except Exception as exc:  # noqa: BLE001
        print(f"[Alternea Voice] Note: Voice runner exited or not configured: {exc}")


def main():
    parser = argparse.ArgumentParser(description="CTS PharmaAssist Multi-Agent & Voice Platform")
    parser.add_argument(
        "--mode",
        choices=["api", "voice", "both"],
        default="both",
        help="Service mode to run: 'api' (Litestar Agent Service), 'voice' (Alternea Voice Bot), or 'both' (concurrent)",
    )
    parser.add_argument(
        "--host",
        default="0.0.0.0",
        help="Host to bind the Agent Service (default: 0.0.0.0)",
    )
    parser.add_argument(
        "--port",
        type=int,
        default=8000,
        help="Port to bind the Agent Service (default: 8000)",
    )

    args, _unknown = parser.parse_known_args()

    if args.mode == "api":
        start_agent_service(host=args.host, port=args.port)
    elif args.mode == "voice":
        start_voice_agent()
    else:
        # Default: Run API service on main thread, with voice runner support
        # Start API service in a background daemon thread
        api_thread = threading.Thread(
            target=start_agent_service,
            kwargs={"host": args.host, "port": args.port},
            daemon=True,
        )
        api_thread.start()

        # Check if voice runner arguments or Pipecat runner is invoked
        try:
            from alternea_voice.features.rtc.bot import bot
            from pipecat.runner.run import main as pipecat_main

            # Run voice bot runner on main loop
            pipecat_main()
        except KeyboardInterrupt:
            print("\n[CTS PharmaAssist] Shutting down gracefully...")
        except Exception as exc:  # noqa: BLE001
            print(f"[CTS PharmaAssist] Running in Agent API mode (Voice standby: {exc})")
            # Keep the API service running on main thread
            try:
                api_thread.join()
            except KeyboardInterrupt:
                print("\n[CTS PharmaAssist] Server stopped.")


if __name__ == "__main__":
    main()
