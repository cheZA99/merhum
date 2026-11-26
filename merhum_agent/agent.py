import logging

import httpx

from config import Settings
from groq_client import call_groq
from tools import TOOLS, AgentError, run_tool

# Copied word for word from the .NET GroqService so users see the same message from both assistants.
FALLBACK_TEXT = "Žao mi je, trenutno ne mogu odgovoriti na Vaš upit. Molimo pokušajte ponovo za nekoliko trenutaka."

MAX_ITERATIONS = 5

SYSTEM_PROMPT = (
    "Vi ste Merhum asistent za porodice u Bosni i Hercegovini. "
    "Odgovarajte kratko, na bosanskom jeziku (ijekavica: uvijek, mjesto, vrijeme), sa suosjećajnim tonom. "
    "Pišite samo običan tekst: bez emojija i bez markdowna (bez zvjezdica, naslova i listi). "
    "Za podatke o grobljima koristite alat search_cemeteries. "
    "Za cijene, usluge i pogrebna preduzeća koristite alat list_service_prices; sve cijene su u KM. "
    "Odgovarajte isključivo na osnovu rezultata alata i nikada ne izmišljajte brojeve. "
    "Ako alat ne vrati podatke, recite iskreno da ih nemate. "
    # The chat has no history, so a clarifying question could never be answered; cover both meanings instead.
    "Ako pitanje korisnika može razumno značiti više stvari, nemojte postavljati pitanje za pojašnjenje, "
    "nego u istom odgovoru kratko odgovorite za dva najvjerovatnija značenja "
    "(na primjer, za \"najjeftinija usluga\" navedite najjeftiniju uslugu uopšte i najjeftiniji ukop). "
    "Ako je značenje jasno, odgovorite direktno."
)

logger = logging.getLogger(__name__)


def remove_markdown(text: str) -> str:
    # The prompt forbids markdown but the model sometimes ignores it, and the apps show the reply as raw text.
    text = text.replace("**", "").replace("__", "")

    lines = []
    for line in text.split("\n"):
        stripped = line.lstrip()
        if stripped.startswith("#"):
            line = stripped.lstrip("#").lstrip()
        lines.append(line)
    return "\n".join(lines)


async def answer(settings: Settings, authorization: str, user_message: str) -> str:
    try:
        return await run_loop(settings, authorization, user_message)
    except httpx.TimeoutException as error:
        logger.warning("Request to %s timed out.", error.request.url)
    except httpx.HTTPStatusError as error:
        logger.warning(
            "%s returned status %s. Body: %s",
            error.request.url,
            error.response.status_code,
            error.response.text,
        )
    except httpx.HTTPError as error:
        logger.warning("HTTP request failed: %r", error)
    except AgentError as error:
        logger.warning("Agent stopped: %s", error)
    except (ValueError, KeyError, IndexError) as error:
        logger.warning("Unexpected response shape: %r", error)
    return FALLBACK_TEXT


async def run_loop(settings: Settings, authorization: str, user_message: str) -> str:
    messages = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": user_message},
    ]

    for iteration in range(1, MAX_ITERATIONS + 1):
        assistant_message = await call_groq(settings, messages, TOOLS)
        tool_calls = assistant_message.get("tool_calls")

        if not tool_calls:
            content = assistant_message.get("content")
            if not content:
                raise AgentError("Groq returned an empty answer.")
            logger.info("Final answer after %d model call(s).", iteration)
            return remove_markdown(content)

        # Send back only the fields the API documents, not gpt-oss's extra "reasoning" text.
        messages.append(
            {
                "role": "assistant",
                "content": assistant_message.get("content"),
                "tool_calls": tool_calls,
            }
        )

        for tool_call in tool_calls:
            result = await run_tool(settings, authorization, tool_call)
            messages.append(
                {
                    "role": "tool",
                    "tool_call_id": tool_call["id"],
                    "name": tool_call["function"]["name"],
                    "content": result,
                }
            )

    raise AgentError(f"No final answer after {MAX_ITERATIONS} model calls.")
