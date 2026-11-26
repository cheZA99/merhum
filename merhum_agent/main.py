import logging

from fastapi import Depends, FastAPI, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel

from agent import answer
from config import load_settings

# Without this, Python only prints WARNING and above, and our INFO logs would be hidden.
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")

settings = load_settings()
app = FastAPI()

# auto_error=False so a missing token reaches our own check and always returns 401 with our message.
bearer_scheme = HTTPBearer(auto_error=False)


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.get("/greet/{name}")
async def greet(name: str):
    return {"message": f"Selam, {name}"}


class ChatRequest(BaseModel):
    message: str


class ChatResponse(BaseModel):
    response: str


@app.post("/chat")
async def chat(
    request: ChatRequest,
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> ChatResponse:
    # Without the user's token every tool call would fail, so reject early with a clear status.
    if credentials is None:
        raise HTTPException(status_code=401, detail="Missing Bearer token in the Authorization header.")

    authorization = f"Bearer {credentials.credentials}"
    reply = await answer(settings, authorization, request.message)
    return ChatResponse(response=reply)
