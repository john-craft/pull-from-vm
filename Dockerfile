FROM demonstrationorg/dhi-python:3.13-fips-dev AS builder
# FROM python:3.11-slim

WORKDIR /app

RUN apt-get update

RUN pip install uv

# Copy only dependency files first for better layer caching
COPY pyproject.toml .

# Install dependencies
RUN python -m uv sync

# Copy application code
COPY deploy.py .

FROM demonstrationorg/dhi-python:3.13-fips AS runtime
WORKDIR /app

# Copy only the virtual environment with installed dependencies
COPY --from=builder /app/.venv /app/.venv

# Copy only necessary application files
COPY --from=builder /app/deploy.py /app/deploy.py
COPY --from=builder /app/pyproject.toml /app/pyproject.toml

EXPOSE 8000
CMD ["python", "-m", "uv", "run", "python", "deploy.py"]
