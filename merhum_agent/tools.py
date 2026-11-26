import json
import logging
import time

from pydantic import BaseModel, ConfigDict, ValidationError

from config import Settings
from merhum_api import get_cemeteries, get_service_prices

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

LIST_SERVICE_PRICES_TOOL = {
    "type": "function",
    "function": {
        "name": "list_service_prices",
        "description": (
            "Returns active funeral services offered by funeral homes in the Merhum system, "
            "with funeralHomeName, serviceTypeName and price. All prices are in KM (convertible marks, BAM). "
            "Use this tool whenever the user asks about prices, costs, services or funeral homes. "
            "It takes no arguments and returns all funeral homes, so compare or filter the results yourself."
        ),
        "parameters": {
            "type": "object",
            "properties": {},
            "required": [],
        },
    },
}

TOOLS = [SEARCH_CEMETERIES_TOOL, LIST_SERVICE_PRICES_TOOL]


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


class ListServicePricesArguments(BaseModel):
    # No fields: the tool takes no arguments, so any argument the model sends is rejected.
    model_config = ConfigDict(extra="forbid")


def parse_service_prices_arguments(arguments_json: str) -> ListServicePricesArguments:
    try:
        return ListServicePricesArguments.model_validate_json(arguments_json)
    except ValidationError as error:
        raise AgentError(f"Invalid arguments for list_service_prices: {arguments_json}") from error


async def run_list_service_prices(settings: Settings, authorization: str, arguments_json: str) -> str:
    parse_service_prices_arguments(arguments_json)

    started = time.perf_counter()
    prices = await get_service_prices(settings, authorization)
    elapsed_ms = (time.perf_counter() - started) * 1000

    logger.info(
        "Tool list_service_prices returned %d result(s) in %.0f ms",
        len(prices),
        elapsed_ms,
    )
    return json.dumps(prices, ensure_ascii=False)


async def run_tool(settings: Settings, authorization: str, tool_call: dict) -> str:
    name = tool_call["function"]["name"]
    arguments_json = tool_call["function"]["arguments"]

    if name == "search_cemeteries":
        return await run_search_cemeteries(settings, authorization, arguments_json)
    if name == "list_service_prices":
        return await run_list_service_prices(settings, authorization, arguments_json)

    raise AgentError(f"Model asked for an unknown tool: {name}")
