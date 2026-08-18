# ruff: noqa: I001, F401
import sys
import os

# Append server/src to sys.path
sys.path.append(os.path.join(os.path.dirname(__file__), "server", "src"))

# pyrefly: ignore [missing-import]
from alternea_voice.features.rtc.bot import bot
# pyrefly: ignore [missing-import]
from pipecat.runner.run import main

if __name__ == "__main__":
    main()
