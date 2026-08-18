FROM python:3.13-slim

WORKDIR /app

# The user project has pyproject.toml and main.py in the root directory,
# so we copy them from the build context (which will be set to the project root).
COPY pyproject.toml .python-version* ./

# In a standard setup, we would install dependencies via `pip install .`
# However, because the root directory contains 'client' and 'server' folders
# and pyproject.toml lacks an explicit build-system, `pip install .` fails 
# due to multiple top-level packages discovered.
# Since the dependencies list is currently empty, we can skip this step safely.
# RUN pip install . 

COPY main.py ./

# The backend script simply prints output and exits.
# Using python main.py as requested.
CMD ["python", "main.py"]
