"""
Simple FastAPI deployment stub
"""
from fastapi import FastAPI
import uvicorn

app = FastAPI(title="OpenVLA DD API")


@app.get("/")
async def root():
    return {"status": "ok", "message": "OpenVLA DD API is running"}


@app.get("/health")
async def health():
    return {"status": "healthy"}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
