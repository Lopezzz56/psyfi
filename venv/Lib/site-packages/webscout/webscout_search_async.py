from __future__ import annotations

import asyncio
import os
import warnings
from datetime import datetime, timezone
from functools import cached_property
from itertools import cycle
from random import choice, shuffle
from time import time
from types import TracebackType
from typing import Any, Dict, List, Optional, Type, Union, cast, AsyncIterator

import httpx
from lxml.etree import _Element
from lxml.html import HTMLParser as LHTMLParser
from lxml.html import document_fromstring

from .exceptions import ConversationLimitException, RatelimitE, TimeoutE, WebscoutE
from .utils import (
    _expand_proxy_tb_alias,
    _extract_vqd,
    _normalize,
    _normalize_url,
    json_loads,
)




class AsyncWEBS:
    """Asynchronous webscout class to get search results."""

    _impersonates = (
        "chrome_100", "chrome_101", "chrome_104", "chrome_105", "chrome_106", "chrome_107",
        "chrome_108", "chrome_109", "chrome_114", "chrome_116", "chrome_117", "chrome_118",
        "chrome_119", "chrome_120", "chrome_123", "chrome_124", "chrome_126", "chrome_127",
        "chrome_128", "chrome_129", "chrome_130", "chrome_131", "chrome_133",
        "safari_ios_16.5", "safari_ios_17.2", "safari_ios_17.4.1", "safari_ios_18.1.1",
        "safari_15.3", "safari_15.5", "safari_15.6.1", "safari_16", "safari_16.5",
        "safari_17.0", "safari_17.2.1", "safari_17.4.1", "safari_17.5",
        "safari_18", "safari_18.2",
        "safari_ipad_18",
        "edge_101", "edge_122", "edge_127", "edge_131",
        "firefox_109", "firefox_117", "firefox_128", "firefox_133", "firefox_135",
    )
    _impersonates_os = ("android", "ios", "linux", "macos", "windows")
    _chat_models = {
        "gpt-4o-mini": "gpt-4o-mini",
        "llama-3.3-70b": "meta-llama/Llama-3.3-70B-Instruct-Turbo",
        "claude-3-haiku": "claude-3-haiku-20240307",
        "o3-mini": "o3-mini",
        "mistral-small-3": "mistralai/Mistral-Small-24B-Instruct-2501",
    }

    def __init__(
        self,
        headers: Optional[Dict[str, str]] = None,
        proxy: Optional[str] = None,
        proxies: Union[Dict[str, str], str, None] = None,  # deprecated
        timeout: Optional[int] = 10,
        verify: bool = True,
    ) -> None:
        """Initialize the AsyncWEBS object.

        Args:
            headers (dict, optional): Dictionary of headers for the HTTP client. Defaults to None.
            proxy (str, optional): proxy for the HTTP client, supports http/https/socks5 protocols.
                example: "http://user:pass@example.com:3128". Defaults to None.
            timeout (int, optional): Timeout value for the HTTP client. Defaults to 10.
            verify (bool): SSL verification when making the request. Defaults to True.
        """
        ddgs_proxy: Optional[str] = os.environ.get("DDGS_PROXY")
        self.proxy: Optional[str] = ddgs_proxy if ddgs_proxy else _expand_proxy_tb_alias(proxy)
        assert self.proxy is None or isinstance(self.proxy, str), "proxy must be a str"
        if not proxy and proxies:
            warnings.warn("'proxies' is deprecated, use 'proxy' instead.", stacklevel=1)
            self.proxy = proxies.get("http") or proxies.get("https") if isinstance(proxies, dict) else proxies

        default_headers = {
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.5",
            "Accept-Encoding": "gzip, deflate, br",
            "DNT": "1",
            "Connection": "keep-alive",
            "Upgrade-Insecure-Requests": "1",
            "Sec-Fetch-Dest": "document",
            "Sec-Fetch-Mode": "navigate",
            "Sec-Fetch-Site": "none",
            "Sec-Fetch-User": "?1",
            "Referer": "https://duckduckgo.com/",
        }

        self.headers = headers if headers else {}
        self.headers.update(default_headers)

        self.client = httpx.AsyncClient(
            headers=self.headers,
            proxies=self.proxy,
            timeout=timeout,
            follow_redirects=False,
            verify=verify,
        )
        self.sleep_timestamp = 0.0

        self._exception_event = asyncio.Event()
        self._chat_messages: List[Dict[str, str]] = []
        self._chat_tokens_count = 0
        self._chat_vqd: str = ""
        self._chat_vqd_hash: str = ""
        self._chat_xfe: str = ""

    async def __aenter__(self) -> AsyncWEBS:
        return self

    async def __aexit__(
        self,
        exc_type: Optional[Type[BaseException]] = None,
        exc_val: Optional[BaseException] = None,
        exc_tb: Optional[TracebackType] = None,
    ) -> None:
        await self.client.aclose()

    @cached_property
    def parser(self) -> LHTMLParser:
        """Get HTML parser."""
        return LHTMLParser(remove_blank_text=True, remove_comments=True, remove_pis=True, collect_ids=False)

    async def _sleep(self, sleeptime: float = 0.75) -> None:
        """Sleep between API requests."""
        delay = 0.0 if not self.sleep_timestamp else 0.0 if time() - self.sleep_timestamp >= 20 else sleeptime
        self.sleep_timestamp = time()
        await asyncio.sleep(delay)

    async def _get_url(
        self,
        method: str,
        url: str,
        params: Optional[Dict[str, str]] = None,
        content: Optional[bytes] = None,
        data: Optional[Dict[str, str]] = None,
        headers: Optional[Dict[str, str]] = None,
        cookies: Optional[Dict[str, str]] = None,
        json: Any = None,
        timeout: Optional[float] = None,
    ) -> Any:
        """Make HTTP request with proper rate limiting."""
        await self._sleep()
        try:
            resp = await self.client.request(
                method,
                url,
                params=params,
                content=content,
                data=data,
                headers=headers,
                cookies=cookies,
                json=json,
                timeout=timeout or self.timeout,
            )
        except Exception as ex:
            if "time" in str(ex).lower():
                raise TimeoutE(f"{url} {type(ex).__name__}: {ex}") from ex
            raise WebscoutE(f"{url} {type(ex).__name__}: {ex}") from ex

        if resp.status_code == 200:
            return resp
        elif resp.status_code in (202, 301, 403, 400, 429, 418):
            raise RatelimitE(f"{resp.url} {resp.status_code} Ratelimit")
        raise WebscoutE(f"{resp.url} return None. {params=} {content=} {data=}")

    async def _get_vqd(self, keywords: str) -> str:
        """Get vqd value for a search query."""
        resp_content = (await self._get_url("GET", "https://duckduckgo.com", params={"q": keywords})).content
        return _extract_vqd(resp_content, keywords)

    async def achat_yield(self, keywords: str, model: str = "gpt-4o-mini", timeout: int = 30, max_retries: int = 3) -> AsyncIterator[str]:
        """Initiates an async chat session with webscout AI.

        Args:
            keywords (str): The initial message or question to send to the AI.
            model (str): The model to use: "gpt-4o-mini", "llama-3.3-70b", "claude-3-haiku",
                "o3-mini", "mistral-small-3". Defaults to "gpt-4o-mini".
            timeout (int): Timeout value for the HTTP client. Defaults to 30.
            max_retries (int): Maximum number of retry attempts for rate limited requests. Defaults to 3.

        Yields:
            str: Chunks of the response from the AI.
        """
        # Get Cloudflare Turnstile token
        async def get_turnstile_token():
            try:
                # Visit the DuckDuckGo chat page to get the Turnstile token
                resp_content = (await self._get_url(
                    method="GET",
                    url="https://duckduckgo.com/?q=DuckDuckGo+AI+Chat&ia=chat&duckai=1",
                )).content

                # Extract the Turnstile token if available
                if b'cf-turnstile-response' in resp_content:
                    token = resp_content.split(b'cf-turnstile-response="', maxsplit=1)[1].split(b'"', maxsplit=1)[0].decode()
                    return token
                return ""
            except Exception:
                return ""

        # x-fe-version
        if not self._chat_xfe:
            resp_content = (await self._get_url(
                method="GET",
                url="https://duckduckgo.com/?q=DuckDuckGo+AI+Chat&ia=chat&duckai=1",
            )).content
            try:
                xfe1 = resp_content.split(b'__DDG_BE_VERSION__="', maxsplit=1)[1].split(b'"', maxsplit=1)[0].decode()
                xfe2 = resp_content.split(b'__DDG_FE_CHAT_HASH__="', maxsplit=1)[1].split(b'"', maxsplit=1)[0].decode()
                self._chat_xfe = f"{xfe1}-{xfe2}"
            except Exception as ex:
                raise WebscoutE(
                    f"achat_yield() Error to get _chat_xfe: {type(ex).__name__}: {ex}"
                ) from ex
        # vqd
        if not self._chat_vqd:
            resp = await self._get_url(
                method="GET", url="https://duckduckgo.com/duckchat/v1/status", headers={"x-vqd-accept": "1"}
            )
            self._chat_vqd = resp.headers.get("x-vqd-4", "")
            self._chat_vqd_hash = resp.headers.get("x-vqd-hash-1", "")

        self._chat_messages.append({"role": "user", "content": keywords})
        self._chat_tokens_count += max(len(keywords) // 4, 1)  # approximate number of tokens
        if model not in self._chat_models:
            warnings.warn(f"{model=} is unavailable. Using 'gpt-4o-mini'", stacklevel=1)
            model = "gpt-4o-mini"

        # Get Cloudflare Turnstile token
        turnstile_token = await get_turnstile_token()

        json_data = {
            "model": self._chat_models[model],
            "messages": self._chat_messages,
        }

        # Add Turnstile token if available
        if turnstile_token:
            json_data["cf-turnstile-response"] = turnstile_token

        # Enhanced headers to better mimic a real browser
        chat_headers = {
            "x-fe-version": self._chat_xfe,
            "x-vqd-4": self._chat_vqd,
            "x-vqd-hash-1": "",
            "Accept": "text/event-stream",
            "Accept-Language": "en-US,en;q=0.9",
            "Cache-Control": "no-cache",
            "Content-Type": "application/json",
            "DNT": "1",
            "Origin": "https://duckduckgo.com",
            "Referer": "https://duckduckgo.com/",
            "Sec-Fetch-Dest": "empty",
            "Sec-Fetch-Mode": "cors",
            "Sec-Fetch-Site": "same-origin",
            "User-Agent": self.client.headers.get("User-Agent", "")
        }

        # Retry logic for rate limited requests
        retry_count = 0
        while retry_count <= max_retries:
            try:
                resp = await self._get_url(
                    method="POST",
                    url="https://duckduckgo.com/duckchat/v1/chat",
                    headers=chat_headers,
                    json=json_data,
                    timeout=timeout,
                )

                self._chat_vqd = resp.headers.get("x-vqd-4", "")
                self._chat_vqd_hash = resp.headers.get("x-vqd-hash-1", "")
                chunks = []

                async for chunk in resp.aiter_bytes():
                    lines = chunk.split(b"data:")
                    for line in lines:
                        if line := line.strip():
                            if line == b"[DONE]":
                                break
                            if line == b"[DONE][LIMIT_CONVERSATION]":
                                raise ConversationLimitException("ERR_CONVERSATION_LIMIT")
                            x = json_loads(line)
                            if isinstance(x, dict):
                                if x.get("action") == "error":
                                    err_message = x.get("type", "")
                                    if x.get("status") == 429:
                                        raise (
                                            ConversationLimitException(err_message)
                                            if err_message == "ERR_CONVERSATION_LIMIT"
                                            else RatelimitE(err_message)
                                        )
                                    raise WebscoutE(err_message)
                                elif message := x.get("message"):
                                    chunks.append(message)
                                    yield message

                # If we get here, the request was successful
                result = "".join(chunks)
                self._chat_messages.append({"role": "assistant", "content": result})
                self._chat_tokens_count += len(result)
                return

            except RatelimitE as ex:
                retry_count += 1
                if retry_count > max_retries:
                    raise WebscoutE(f"achat_yield() Rate limit exceeded after {max_retries} retries: {ex}") from ex

                # Get a fresh Turnstile token for the retry
                turnstile_token = await get_turnstile_token()
                if turnstile_token:
                    json_data["cf-turnstile-response"] = turnstile_token

                # Exponential backoff
                sleep_time = 2 ** retry_count
                await asyncio.sleep(sleep_time)

            except Exception as ex:
                raise WebscoutE(f"achat_yield() {type(ex).__name__}: {ex}") from ex

    async def achat(self, keywords: str, model: str = "gpt-4o-mini", timeout: int = 30, max_retries: int = 3) -> str:
        """Initiates an async chat session with webscout AI.

        Args:
            keywords (str): The initial message or question to send to the AI.
            model (str): The model to use: "gpt-4o-mini", "llama-3.3-70b", "claude-3-haiku",
                "o3-mini", "mistral-small-3". Defaults to "gpt-4o-mini".
            timeout (int): Timeout value for the HTTP client. Defaults to 30.
            max_retries (int): Maximum number of retry attempts for rate limited requests. Defaults to 3.

        Returns:
            str: The response from the AI.
        """
        chunks = []
        async for chunk in self.achat_yield(keywords, model, timeout, max_retries):
            chunks.append(chunk)
        return "".join(chunks)

    async def atext(
        self,
        keywords: str,
        region: str = "wt-wt",
        safesearch: str = "moderate",
        timelimit: Optional[str] = None,
        backend: str = "auto",
        max_results: Optional[int] = None,
    ) -> List[Dict[str, str]]:
        """webscout async text search. Query params: https://duckduckgo.com/params.

        Args:
            keywords: keywords for query.
            region: wt-wt, us-en, uk-en, ru-ru, etc. Defaults to "wt-wt".
            safesearch: on, moderate, off. Defaults to "moderate".
            timelimit: d, w, m, y. Defaults to None.
            backend: auto, html, lite. Defaults to auto.
                auto - try all backends in random order,
                html - collect data from https://html.duckduckgo.com,
                lite - collect data from https://lite.duckduckgo.com.
            max_results: max number of results. If None, returns results only from the first response. Defaults to None.

        Returns:
            List of dictionaries with search results.

        Raises:
            WebscoutE: Base exception for webscout errors.
            RatelimitE: Inherits from WebscoutE, raised for exceeding API request rate limits.
            TimeoutE: Inherits from WebscoutE, raised for API request timeouts.
        """
        if backend in ("api", "ecosia"):
            warnings.warn(f"{backend=} is deprecated, using backend='auto'", stacklevel=2)
            backend = "auto"
        backends = ["html", "lite"] if backend == "auto" else [backend]
        shuffle(backends)

        results, err = [], None
        for b in backends:
            try:
                if b == "html":
                    results = await self._text_html(keywords, region, timelimit, max_results)
                elif b == "lite":
                    results = await self._text_lite(keywords, region, timelimit, max_results)
                return results
            except Exception as ex:
                err = ex

        raise WebscoutE(err)

    async def _text_html(
        self,
        keywords: str,
        region: str = "wt-wt",
        timelimit: Optional[str] = None,
        max_results: Optional[int] = None,
    ) -> List[Dict[str, str]]:
        """HTML backend for text search."""
        assert keywords, "keywords is mandatory"

        payload = {
            "q": keywords,
            "s": "0",
            "o": "json",
            "api": "d.js",
            "vqd": "",
            "kl": region,
            "bing_market": region,
        }
        if timelimit:
            payload["df"] = timelimit

        cache = set()
        results: List[Dict[str, str]] = []

        for _ in range(5):
            resp_content = await self._get_url("POST", "https://html.duckduckgo.com/html", data=payload)
            if b"No  results." in resp_content:
                return results

            tree = document_fromstring(resp_content, self.parser)
            elements = tree.xpath("//div[h2]")
            if not isinstance(elements, list):
                return results

            for e in elements:
                if isinstance(e, _Element):
                    hrefxpath = e.xpath("./a/@href")
                    href = str(hrefxpath[0]) if hrefxpath and isinstance(hrefxpath, list) else None
                    if (
                        href
                        and href not in cache
                        and not href.startswith(
                            ("http://www.google.com/search?q=", "https://duckduckgo.com/y.js?ad_domain")
                        )
                    ):
                        cache.add(href)
                        titlexpath = e.xpath("./h2/a/text()")
                        title = str(titlexpath[0]) if titlexpath and isinstance(titlexpath, list) else ""
                        bodyxpath = e.xpath("./a//text()")
                        body = "".join(str(x) for x in bodyxpath) if bodyxpath and isinstance(bodyxpath, list) else ""
                        results.append(
                            {
                                "title": _normalize(title),
                                "href": _normalize_url(href),
                                "body": _normalize(body),
                            }
                        )
                        if max_results and len(results) >= max_results:
                            return results

            npx = tree.xpath('.//div[@class="nav-link"]')
            if not npx or not max_results:
                return results
            next_page = npx[-1] if isinstance(npx, list) else None
            if isinstance(next_page, _Element):
                names = next_page.xpath('.//input[@type="hidden"]/@name')
                values = next_page.xpath('.//input[@type="hidden"]/@value')
                if isinstance(names, list) and isinstance(values, list):
                    payload = {str(n): str(v) for n, v in zip(names, values)}

        return results

    async def _text_lite(
        self,
        keywords: str,
        region: str = "wt-wt",
        timelimit: Optional[str] = None,
        max_results: Optional[int] = None,
    ) -> List[Dict[str, str]]:
        """Lite backend for text search."""
        assert keywords, "keywords is mandatory"

        payload = {
            "q": keywords,
            "s": "0",
            "o": "json",
            "api": "d.js",
            "vqd": "",
            "kl": region,
            "bing_market": region,
        }
        if timelimit:
            payload["df"] = timelimit

        cache = set()
        results: List[Dict[str, str]] = []

        for _ in range(5):
            resp_content = await self._get_url("POST", "https://lite.duckduckgo.com/lite/", data=payload)
            if b"No more results." in resp_content:
                return results

            tree = document_fromstring(resp_content, self.parser)
            elements = tree.xpath("//table[last()]//tr")
            if not isinstance(elements, list):
                return results

            data = zip(cycle(range(1, 5)), elements)
            for i, e in data:
                if isinstance(e, _Element):
                    if i == 1:
                        hrefxpath = e.xpath(".//a//@href")
                        href = str(hrefxpath[0]) if hrefxpath and isinstance(hrefxpath, list) else None
                        if (
                            href is None
                            or href in cache
                            or href.startswith(
                                ("http://www.google.com/search?q=", "https://duckduckgo.com/y.js?ad_domain")
                            )
                        ):
                            [next(data, None) for _ in range(3)]  # skip block(i=1,2,3,4)
                        else:
                            cache.add(href)
                            titlexpath = e.xpath(".//a//text()")
                            title = str(titlexpath[0]) if titlexpath and isinstance(titlexpath, list) else ""
                    elif i == 2:
                        bodyxpath = e.xpath(".//td[@class='result-snippet']//text()")
                        body = (
                            "".join(str(x) for x in bodyxpath).strip()
                            if bodyxpath and isinstance(bodyxpath, list)
                            else ""
                        )
                        if href:
                            results.append(
                                {
                                    "title": _normalize(title),
                                    "href": _normalize_url(href),
                                    "body": _normalize(body),
                                }
                            )
                            if max_results and len(results) >= max_results:
                                return results

            next_page_s = tree.xpath("//form[./input[contains(@value, 'ext')]]/input[@name='s']/@value")
            if not next_page_s or not max_results:
                return results
            elif isinstance(next_page_s, list):
                payload["s"] = str(next_page_s[0])

        return results

    async def aimages(
        self,
        keywords: str,
        region: str = "wt-wt",
        safesearch: str = "moderate",
        timelimit: Optional[str] = None,
        size: Optional[str] = None,
        color: Optional[str] = None,
        type_image: Optional[str] = None,
        layout: Optional[str] = None,
        license_image: Optional[str] = None,
        max_results: Optional[int] = None,
    ) -> List[Dict[str, str]]:
        """webscout async images search. Query params: https://duckduckgo.com/params.

        Args:
            keywords: keywords for query.
            region: wt-wt, us-en, uk-en, ru-ru, etc. Defaults to "wt-wt".
            safesearch: on, moderate, off. Defaults to "moderate".
            timelimit: Day, Week, Month, Year. Defaults to None.
            size: Small, Medium, Large, Wallpaper. Defaults to None.
            color: color, Monochrome, Red, Orange, Yellow, Green, Blue,
                Purple, Pink, Brown, Black, Gray, Teal, White. Defaults to None.
            type_image: photo, clipart, gif, transparent, line.
                Defaults to None.
            layout: Square, Tall, Wide. Defaults to None.
            license_image: any (All Creative Commons), Public (PublicDomain),
                Share (Free to Share and Use), ShareCommercially (Free to Share and Use Commercially),
                Modify (Free to Modify, Share, and Use), ModifyCommercially (Free to Modify, Share, and
                Use Commercially). Defaults to None.
            max_results: max number of results. If None, returns results only from the first response. Defaults to None.

        Returns:
            List of dictionaries with images search results.

        Raises:
            WebscoutE: Base exception for webscout errors.
            RatelimitE: Inherits from WebscoutE, raised for exceeding API request rate limits.
            TimeoutE: Inherits from WebscoutE, raised for API request timeouts.
        """
        result = await self._loop.run_in_executor(
            self._executor,
            super().images,
            keywords,
            region,
            safesearch,
            timelimit,
            size,
            color,
            type_image,
            layout,
            license_image,
            max_results,
        )
        return result

    async def avideos(
        self,
        keywords: str,
        region: str = "wt-wt",
        safesearch: str = "moderate",
        timelimit: Optional[str] = None,
        resolution: Optional[str] = None,
        duration: Optional[str] = None,
        license_videos: Optional[str] = None,
        max_results: Optional[int] = None,
    ) -> List[Dict[str, str]]:
        """webscout async videos search. Query params: https://duckduckgo.com/params.

        Args:
            keywords: keywords for query.
            region: wt-wt, us-en, uk-en, ru-ru, etc. Defaults to "wt-wt".
            safesearch: on, moderate, off. Defaults to "moderate".
            timelimit: d, w, m. Defaults to None.
            resolution: high, standart. Defaults to None.
            duration: short, medium, long. Defaults to None.
            license_videos: creativeCommon, youtube. Defaults to None.
            max_results: max number of results. If None, returns results only from the first response. Defaults to None.

        Returns:
            List of dictionaries with videos search results.

        Raises:
            WebscoutE: Base exception for webscout errors.
            RatelimitE: Inherits from WebscoutE, raised for exceeding API request rate limits.
            TimeoutE: Inherits from WebscoutE, raised for API request timeouts.
        """
        result = await self._loop.run_in_executor(
            self._executor,
            super().videos,
            keywords,
            region,
            safesearch,
            timelimit,
            resolution,
            duration,
            license_videos,
            max_results,
        )
        return result

    async def anews(
        self,
        keywords: str,
        region: str = "wt-wt",
        safesearch: str = "moderate",
        timelimit: Optional[str] = None,
        max_results: Optional[int] = None,
    ) -> List[Dict[str, str]]:
        """webscout async news search. Query params: https://duckduckgo.com/params.

        Args:
            keywords: keywords for query.
            region: wt-wt, us-en, uk-en, ru-ru, etc. Defaults to "wt-wt".
            safesearch: on, moderate, off. Defaults to "moderate".
            timelimit: d, w, m. Defaults to None.
            max_results: max number of results. If None, returns results only from the first response. Defaults to None.

        Returns:
            List of dictionaries with news search results.

        Raises:
            WebscoutE: Base exception for webscout errors.
            RatelimitE: Inherits from WebscoutE, raised for exceeding API request rate limits.
            TimeoutE: Inherits from WebscoutE, raised for API request timeouts.
        """
        result = await self._loop.run_in_executor(
            self._executor,
            super().news,
            keywords,
            region,
            safesearch,
            timelimit,
            max_results,
        )
        return result

    async def aanswers(
        self,
        keywords: str,
    ) -> List[Dict[str, str]]:
        """webscout async instant answers. Query params: https://duckduckgo.com/params.

        Args:
            keywords: keywords for query,

        Returns:
            List of dictionaries with instant answers results.

        Raises:
            WebscoutE: Base exception for webscout errors.
            RatelimitE: Inherits from WebscoutE, raised for exceeding API request rate limits.
            TimeoutE: Inherits from WebscoutE, raised for API request timeouts.
        """
        result = await self._loop.run_in_executor(
            self._executor,
            super().answers,
            keywords,
        )
        return result

    async def asuggestions(
        self,
        keywords: str,
        region: str = "wt-wt",
    ) -> List[Dict[str, str]]:
        """webscout async suggestions. Query params: https://duckduckgo.com/params.

        Args:
            keywords: keywords for query.
            region: wt-wt, us-en, uk-en, ru-ru, etc. Defaults to "wt-wt".

        Returns:
            List of dictionaries with suggestions results.

        Raises:
            WebscoutE: Base exception for webscout errors.
            RatelimitE: Inherits from WebscoutE, raised for exceeding API request rate limits.
            TimeoutE: Inherits from WebscoutE, raised for API request timeouts.
        """
        result = await self._loop.run_in_executor(
            self._executor,
            super().suggestions,
            keywords,
            region,
        )
        return result

    async def amaps(
        self,
        keywords: str,
        place: Optional[str] = None,
        street: Optional[str] = None,
        city: Optional[str] = None,
        county: Optional[str] = None,
        state: Optional[str] = None,
        country: Optional[str] = None,
        postalcode: Optional[str] = None,
        latitude: Optional[str] = None,
        longitude: Optional[str] = None,
        radius: int = 0,
        max_results: Optional[int] = None,
    ) -> List[Dict[str, str]]:
        """webscout async maps search. Query params: https://duckduckgo.com/params.

        Args:
            keywords: keywords for query
            place: if set, the other parameters are not used. Defaults to None.
            street: house number/street. Defaults to None.
            city: city of search. Defaults to None.
            county: county of search. Defaults to None.
            state: state of search. Defaults to None.
            country: country of search. Defaults to None.
            postalcode: postalcode of search. Defaults to None.
            latitude: geographic coordinate (north-south position). Defaults to None.
            longitude: geographic coordinate (east-west position); if latitude and
                longitude are set, the other parameters are not used. Defaults to None.
            radius: expand the search square by the distance in kilometers. Defaults to 0.
            max_results: max number of results. If None, returns results only from the first response. Defaults to None.

        Returns:
            List of dictionaries with maps search results, or None if there was an error.

        Raises:
            WebscoutE: Base exception for webscout errors.
            RatelimitE: Inherits from WebscoutE, raised for exceeding API request rate limits.
            TimeoutE: Inherits from WebscoutE, raised for API request timeouts.
        """
        result = await self._loop.run_in_executor(
            self._executor,
            super().maps,
            keywords,
            place,
            street,
            city,
            county,
            state,
            country,
            postalcode,
            latitude,
            longitude,
            radius,
            max_results,
        )
        return result

    async def atranslate(
        self,
        keywords: Union[List[str], str],
        from_: Optional[str] = None,
        to: str = "en",
    ) -> List[Dict[str, str]]:
        """webscout async translate.

        Args:
            keywords: string or list of strings to translate.
            from_: translate from (defaults automatically). Defaults to None.
            to: what language to translate. Defaults to "en".

        Returns:
            List od dictionaries with translated keywords.

        Raises:
            WebscoutE: Base exception for webscout errors.
            RatelimitE: Inherits from WebscoutE, raised for exceeding API request rate limits.
            TimeoutE: Inherits from WebscoutE, raised for API request timeouts.
        """
        result = await self._loop.run_in_executor(
            self._executor,
            super().translate,
            keywords,
            from_,
            to,
        )
        return result

    async def aweather(
        self,
        location: str,
        language: str = "en",
    ) -> dict[str, Any]:
        """Async version of weather information retrieval from DuckDuckGo.

        Args:
            location: Location to get weather for.
            language: Language code (e.g. 'en', 'es'). Defaults to "en".

        Returns:
            Dictionary containing weather data with the following structure:
            {
                "location": str,
                "current": {
                    "condition": str,
                    "temperature_c": float,
                    "feels_like_c": float,
                    "humidity": float,
                    "wind_speed_ms": float,
                    "wind_direction": float,
                    "visibility_m": float
                },
                "daily_forecast": List[{
                    "date": str,
                    "condition": str,
                    "max_temp_c": float,
                    "min_temp_c": float,
                    "sunrise": str,
                    "sunset": str
                }],
                "hourly_forecast": List[{
                    "time": str,
                    "condition": str,
                    "temperature_c": float,
                    "feels_like_c": float,
                    "humidity": float,
                    "wind_speed_ms": float,
                    "wind_direction": float,
                    "visibility_m": float
                }]
            }

        Raises:
            WebscoutE: Base exception for webscout errors.
            RatelimitE: Inherits from WebscoutE, raised for exceeding API request rate limits.
            TimeoutE: Inherits from WebscoutE, raised for API request timeouts.
        """
        result = await self._loop.run_in_executor(
            self._executor,
            super().weather,
            location,
            language,
        )
        return result
