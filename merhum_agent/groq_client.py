import httpx

from config import Settings

GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"
GROQ_TIMEOUT_SECONDS = 30.0

# Low temperature, because tool calls and numbers should be predictable.
TEMPERATURE = 0.2
# Same value as the .NET GroqService.
MAX_TOKENS = 1024


async def call_groq(settings: Settings, messages: list[dict], tools: list[dict]) -> dict:
    """Sends the messages and tool definitions to Groq and returns the assistant message. Raises on any HTTP or timeout error."""
    body = {
        "model": settings.groq_model,
        "messages": messages,
        "tools": tools,
        "temperature": TEMPERATURE,
        "max_tokens": MAX_TOKENS,
    }
    headers = {"Authorization": f"Bearer {settings.groq_api_key}"}

    async with httpx.AsyncClient(timeout=GROQ_TIMEOUT_SECONDS) as client:
        response = await client.post(GROQ_URL, json=body, headers=headers)
        response.raise_for_status()
        data = response.json()

    return data["choices"][0]["message"]
