"""Standalone CLI script to bulk index dataset/patient_history.csv records into Pinecone Vector Database."""

import logging
import pathlib
import sys
import time

# Ensure server/src is in sys.path
_current = pathlib.Path(__file__).resolve()
_server_src = _current.parents[2]
if str(_server_src) not in sys.path:
    sys.path.insert(0, str(_server_src))

from dotenv import load_dotenv

load_dotenv()

from agents.patient_history_agent.app.pinecone_client import (
    PineconePatientHistoryClient,
)
from agents.patient_history_agent.app.repository import PatientHistoryRepository

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s - %(message)s",
)
logger = logging.getLogger("ingest_dataset")


def main() -> None:
    logger.info("Initializing Patient History Repository and Pinecone Client...")
    repo = PatientHistoryRepository()
    client = repo.pinecone

    if not client.is_available:
        logger.error(
            "Pinecone client is not available. Please check PINECONE_API_KEY and PINECONE_INDEX_NAME in .env"
        )
        sys.exit(1)

    logger.info("Found %d records in local dataset.", len(repo.records))
    start_time = time.time()

    upserted = repo.sync_dataset_to_pinecone(batch_size=40)
    duration = time.time() - start_time

    logger.info(
        "Successfully upserted %d records to Pinecone in %.2f seconds.",
        upserted,
        duration,
    )
    stats = client.get_stats()
    logger.info("Updated Pinecone Stats: %s", stats)


if __name__ == "__main__":
    main()
