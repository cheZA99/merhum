import json
import logging
import time

from pydantic import BaseModel, ConfigDict, ValidationError

from config import Settings
from merhum_api import get_cemeteries

logger = logging.getLogger(__name__)


class AgentError(Exception):
    """A problem inside the agent loop that should end in the fallback text."""


SEARCH_CEMETERIES_TOOL = {
    "type": "function",
    "function": {
        "name": "search_cemeteries",
        "description": (
            "Returns cemeteries from the Merhum system with name, cityName, availablePlaces and totalPlaces. "
            "The search text matches ONLY the cemetery name or address. It does NOT match the city. "
            "When the user asks about a city, call this tool WITHOUT search and filter the results by cityName yourself."
        ),
        "parameters": {
            "type": "object",
            "properties": {
                "search": {
                    "type": "string",
                    "description": "Part of the cemetery name or address. Leave it out when the user asks about a city.",
                }
            },
            "required": [],
        },
    },
}

TOOLS = [SEARCH_CEMETERIES_TOOL]


class SearchCemeteriesArguments(BaseModel):
    # Reject unknown fields so a hallucinated argument is caught instead of silently ignored.
    model_config = ConfigDict(extra="forbid")

    search: str | None = None


def parse_search_arguments(arguments_json: str) -> SearchCemeteriesArguments:
    try:
        return SearchCemeteriesArguments.model_validate_json(arguments_json)
    except ValidationError as error:
        raise AgentError(f"Invalid arguments for search_cemeteries: {arguments_json}") from error


async def run_search_cemeteries(settings: Settings, authorization: str, arguments_json: str) -> str:
    arguments = parse_search_arguments(arguments_json)
    search = arguments.search.strip() if arguments.search else None

    started = time.perf_counter()
    cemeteries = await get_cemeteries(settings, authorization, search)
    elapsed_ms = (time.perf_counter() - started) * 1000

    logger.info(
        "Tool search_cemeteries search=%r returned %d result(s) in %.0f ms",
        search,
        len(cemeteries),
        elapsed_ms,
    )
    # ensure_ascii=False keeps č, ć, š, ž readable for the model instead of \u escapes.
    return json.dumps(cemeteries, ensure_ascii=False)


async def run_tool(settings: Settings, authorization: str, tool_call: dict) -> str:
    name = tool_call["function"]["name"]
    arguments_json = tool_call["function"]["arguments"]

    if name == "search_cemeteries":
        return await run_search_cemeteries(settings, authorization, arguments_json)

    raise AgentError(f"Model asked for an unknown tool: {name}")
