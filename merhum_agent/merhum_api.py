import logging

import httpx

from config import Settings

logger = logging.getLogger(__name__)

MERHUM_TIMEOUT_SECONDS = 10.0
SEARCH_PAGE_SIZE = 10
# Search cannot match a city, so without search the model needs enough rows to filter by cityName itself.
ALL_CEMETERIES_PAGE_SIZE = 50


async def get_cemeteries(settings: Settings, authorization: str, search: str | None) -> list[dict]:
    """Calls GET /api/Cemetery with the user's own token and returns only the fields the model needs."""
    if search:
        params = {"search": search, "pageSize": SEARCH_PAGE_SIZE}
    else:
        params = {"pageSize": ALL_CEMETERIES_PAGE_SIZE}

    # The user's header is forwarded as-is, so the agent never sees more than the user can.
    headers = {"Authorization": authorization}

    async with httpx.AsyncClient(timeout=MERHUM_TIMEOUT_SECONDS) as client:
        response = await client.get(f"{settings.merhum_api_url}/api/Cemetery", params=params, headers=headers)
        response.raise_for_status()
        data = response.json()

    total_count = data["totalCount"]
    returned_count = len(data["data"])
    if total_count > returned_count:
        # The model only sees what we fetched, so an answer about "all" cemeteries may be incomplete.
        logger.warning(
            "Cemetery search=%r: API has %d result(s) but only %d were fetched.",
            search,
            total_count,
            returned_count,
        )

    cemeteries = []
    for item in data["data"]:
        cemeteries.append(
            {
                "name": item["name"],
                "cityName": item["cityName"],
                "availablePlaces": item["availablePlaces"],
                "totalPlaces": item["totalPlaces"],
            }
        )
    return cemeteries


# Enough to cover every active offering in a small system in one call, and below the API's MaxPageSize of 100.
SERVICE_PRICES_PAGE_SIZE = 50


async def get_service_prices(settings: Settings, authorization: str) -> list[dict]:
    """Calls GET /api/ServiceOffering for active offerings with the user's own token and returns only the fields the model needs."""
    params = {"activeOnly": "true", "pageSize": SERVICE_PRICES_PAGE_SIZE}

    headers = {"Authorization": authorization}

    async with httpx.AsyncClient(timeout=MERHUM_TIMEOUT_SECONDS) as client:
        response = await client.get(f"{settings.merhum_api_url}/api/ServiceOffering", params=params, headers=headers)
        response.raise_for_status()
        data = response.json()

    total_count = data["totalCount"]
    returned_count = len(data["data"])
    if total_count > returned_count:
        logger.warning(
            "Service prices: API has %d result(s) but only %d were fetched.",
            total_count,
            returned_count,
        )

    prices = []
    for item in data["data"]:
        prices.append(
            {
                "funeralHomeName": item["funeralHomeName"],
                "serviceTypeName": item["serviceTypeName"],
                "price": item["price"],
            }
        )
    return prices
