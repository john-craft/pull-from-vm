FROM demonstrationorg/dhi-python:3.13-fips-dev
# FROM python:3.11-slim

WORKDIR /app

RUN apt-get update

RUN pip install uv

COPY . .

RUN python -m uv sync

EXPOSE 8000

CMD ["python", "-m", "uv", "run", "python", "deploy.py"]
