"""
DWEBS - A Google search library with advanced features
"""
import random
from time import sleep
from webscout.scout import Scout
from requests import get
from urllib.parse import unquote, urlencode
from typing import List, Dict, Optional, Union, Iterator, Any
from concurrent.futures import ThreadPoolExecutor


class SearchResult:
    """Class to represent a search result with metadata."""
    
    def __init__(self, url: str, title: str, description: str):
        """
        Initialize a search result.
        
        Args:
            url: The URL of the search result
            title: The title of the search result
            description: The description/snippet of the search result
        """
        self.url = url
        self.title = title
        self.description = description
        # Additional metadata that can be populated
        self.metadata: Dict[str, Any] = {}

    def __repr__(self) -> str:
        """Return string representation of search result."""
        return f"SearchResult(url={self.url}, title={self.title}, description={self.description})"


class GoogleSearch:
    """Google search implementation with configurable parameters and advanced features."""
    
    _executor: ThreadPoolExecutor = ThreadPoolExecutor()
    
    def __init__(
        self,
        timeout: int = 10,
        proxies: Optional[Dict[str, str]] = None,
        verify: bool = True,
        lang: str = "en",
        sleep_interval: float = 0.0
    ):
        """
        Initialize GoogleSearch with custom settings.
        
        Args:
            timeout: Request timeout in seconds
            proxies: Proxy configuration for requests
            verify: Whether to verify SSL certificates
            lang: Search language
            sleep_interval: Sleep time between pagination requests
        """
        self.timeout = timeout
        self.proxies = proxies if proxies else {}
        self.verify = verify
        self.lang = lang
        self.sleep_interval = sleep_interval
        self.base_url = "https://www.google.com/search"
    
    def _get_useragent(self) -> str:
        """
        Generate a random user agent string.
        
        Returns:
            Random user agent string
        """
        lynx_version = f"Lynx/{random.randint(2, 3)}.{random.randint(8, 9)}.{random.randint(0, 2)}"
        libwww_version = f"libwww-FM/{random.randint(2, 3)}.{random.randint(13, 15)}"
        ssl_mm_version = f"SSL-MM/{random.randint(1, 2)}.{random.randint(3, 5)}"
        openssl_version = f"OpenSSL/{random.randint(1, 3)}.{random.randint(0, 4)}.{random.randint(0, 9)}"
        return f"{lynx_version} {libwww_version} {ssl_mm_version} {openssl_version}"
    
    def _make_request(self, term: str, results: int, start: int = 0, search_type: str = None) -> str:
        """
        Make a request to Google search.
        
        Args:
            term: Search query
            results: Number of results to request
            start: Start position for pagination
            search_type: Type of search ('', 'nws', 'isch')
            
        Returns:
            HTML response content
        """
        params = {
            "q": term,
            "num": results + 2,  # Request slightly more than needed
            "hl": self.lang,
            "start": start,
        }
        
        # Add search type if specified
        if search_type:
            params["tbm"] = search_type
            
        try:
            resp = get(
                url=self.base_url,
                headers={
                    "User-Agent": self._get_useragent(),
                    "Accept-Language": self.lang,
                    "Accept-Encoding": "gzip, deflate, br",
                    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
                },
                params=params,
                proxies=self.proxies if any(self.proxies) else None,
                timeout=self.timeout,
                verify=self.verify,
                cookies={
                    'CONSENT': 'PENDING+987',
                    'SOCS': 'CAESHAgBEhIaAB',
                }
            )
            resp.raise_for_status()
            return resp.text
        except Exception as e:
            raise RuntimeError(f"Search request failed: {str(e)}")
    
    def _extract_url(self, raw_link: str) -> Optional[str]:
        """
        Extract actual URL from Google redirect URL.
        
        Args:
            raw_link: Raw link from Google search
            
        Returns:
            Actual URL or None if invalid
        """
        if not raw_link:
            return None
            
        if raw_link.startswith("/url?"):
            try:
                link = unquote(raw_link.split("&")[0].replace("/url?q=", ""))
                return link
            except Exception:
                return None
        elif raw_link.startswith("http"):
            return unquote(raw_link)
        
        return None
    
    def _is_valid_result(self, link: str, fetched_links: set, unique: bool) -> bool:
        """
        Check if search result is valid.
        
        Args:
            link: URL to check
            fetched_links: Set of already fetched links
            unique: Whether to filter duplicate links
            
        Returns:
            Boolean indicating if result is valid
        """
        if any(x in link for x in ["google.", "/search?", "webcache."]):
            return False
            
        if link in fetched_links and unique:
            return False
            
        return True
    
    def _parse_search_results(
        self,
        html: str,
        num_results: int,
        fetched_links: set,
        unique: bool
    ) -> List[SearchResult]:
        """
        Parse search results from HTML.
        
        Args:
            html: HTML content to parse
            num_results: Maximum number of results to return
            fetched_links: Set of already fetched links
            unique: Filter duplicate links
            
        Returns:
            List of SearchResult objects
        """
        results = []
        soup = Scout(html, features="html.parser")
        result_blocks = soup.find_all("div", class_="ezO2md")
        
        if not result_blocks:
            # Try alternative class patterns if the main one doesn't match
            result_blocks = soup.find_all("div", attrs={"class": lambda c: c and "g" in c.split()})
        
        for result in result_blocks:
            # Find the link - looking for various potential Google result classes
            link_tag = result.find("a", class_=["fuLhoc", "ZWRArf"])
            if not link_tag:
                link_tag = result.find("a")
                if not link_tag:
                    continue
            
            raw_link = link_tag.get("href", "")
            link = self._extract_url(raw_link)
            
            if not link:
                continue

            if not self._is_valid_result(link, fetched_links, unique):
                continue

            # Get title - it's the text content of the link tag for these results
            title = link_tag.get_text(strip=True)
            if not title:
                continue

            # Get description - it's in a span with class FrIlee or potentially other classes
            description_tag = result.find("span", class_="FrIlee")
            if not description_tag:
                description_tag = result.find(["div", "span"], class_=lambda c: c and any(x in c for x in ["snippet", "description", "VwiC3b"]))
            
            description = description_tag.get_text(strip=True) if description_tag else ""

            # Create result object
            search_result = SearchResult(link, title, description)
            
            # Add extra metadata if available
            citation = result.find("cite")
            if citation:
                search_result.metadata["source"] = citation.get_text(strip=True)
            
            timestamp = result.find("span", class_=lambda c: c and "ZE5qJf" in c)
            if timestamp:
                search_result.metadata["date"] = timestamp.get_text(strip=True)

            fetched_links.add(link)
            results.append(search_result)
            
            if len(results) >= num_results:
                break
                
        return results
    
    def text(
        self, 
        keywords: str, 
        region: str = None,
        safesearch: str = "moderate",
        max_results: int = 10,
        start_num: int = 0,
        unique: bool = True
    ) -> List[SearchResult]:
        """
        Search Google for web results.
        
        Args:
            keywords: Search query
            region: Region for search results (ISO country code)
            safesearch: SafeSearch setting ("on", "moderate", "off")
            max_results: Maximum number of results to return
            start_num: Starting position for pagination
            unique: Filter duplicate results
            
        Returns:
            List of SearchResult objects with search results
        """
        if not keywords:
            raise ValueError("Search keywords cannot be empty")
            
        # Map safesearch values to Google's safe parameter
        safe_map = {
            "on": "active",
            "moderate": "moderate",
            "off": "off"
        }
        safe = safe_map.get(safesearch.lower(), "moderate")
        
        # Keep track of unique results
        fetched_results = []
        fetched_links = set()
        start = start_num
        
        while len(fetched_results) < max_results:
            response_html = self._make_request(
                term=keywords, 
                results=max_results - len(fetched_results), 
                start=start
            )
            
            results = self._parse_search_results(
                html=response_html,
                num_results=max_results - len(fetched_results),
                fetched_links=fetched_links,
                unique=unique
            )
            
            if not results:
                break
                
            fetched_results.extend(results)
            
            if len(fetched_results) >= max_results:
                break
            
            start += 10
            sleep(self.sleep_interval)
        
        return fetched_results[:max_results]
    
    def news(
        self, 
        keywords: str, 
        region: str = None,
        safesearch: str = "moderate",
        max_results: int = 10
    ) -> List[SearchResult]:
        """
        Search Google News for news results.
        
        Args:
            keywords: Search query
            region: Region for search results (ISO country code)
            safesearch: SafeSearch setting ("on", "moderate", "off")
            max_results: Maximum number of results to return
            
        Returns:
            List of SearchResult objects with news results
        """
        if not keywords:
            raise ValueError("Search keywords cannot be empty")
            
        # Map safesearch values to Google's safe parameter
        safe_map = {
            "on": "active",
            "moderate": "moderate",
            "off": "off"
        }
        safe = safe_map.get(safesearch.lower(), "moderate")
        
        # Keep track of unique results
        fetched_results = []
        fetched_links = set()
        
        response_html = self._make_request(
            term=keywords, 
            results=max_results,
            search_type="nws"
        )
        
        results = self._parse_search_results(
            html=response_html,
            num_results=max_results,
            fetched_links=fetched_links,
            unique=True
        )
        
        return results[:max_results]
    
    def suggestions(self, query: str, region: str = None) -> List[str]:
        """
        Get search suggestions for a query term.
        
        Args:
            query: Search query
            region: Region for suggestions (ISO country code)
        
        Returns:
            List of search suggestions
        """
        if not query:
            raise ValueError("Search query cannot be empty")
            
        try:
            params = {
                "client": "firefox",
                "q": query,
            }
            
            # Add region if specified
            if region and region.lower() != "all":
                params["gl"] = region
            
            url = f"https://www.google.com/complete/search?{urlencode(params)}"
            
            headers = {
                "User-Agent": self._get_useragent(),
                "Accept": "application/json, text/javascript, */*",
                "Accept-Language": self.lang,
            }
            
            response = get(
                url=url,
                headers=headers,
                timeout=self.timeout,
                verify=self.verify
            )
            response.raise_for_status()
            
            # Response format is typically: ["original query", ["suggestion1", "suggestion2", ...]]
            data = response.json()
            if isinstance(data, list) and len(data) > 1 and isinstance(data[1], list):
                return data[1]
            return []
            
        except Exception as e:
            # Return empty list on error instead of raising exception
            return []


# Legacy function support for backward compatibility
def search(term, num_results=10, lang="en", proxy=None, advanced=False, sleep_interval=0, timeout=5, safe="active", ssl_verify=True, region=None, start_num=0, unique=False):
    """Legacy function for backward compatibility."""
    google_search = GoogleSearch(
        timeout=timeout,
        proxies={"https": proxy, "http": proxy} if proxy else None,
        verify=ssl_verify,
        lang=lang,
        sleep_interval=sleep_interval
    )
    
    results = google_search.text(
        keywords=term,
        region=region,
        safesearch="on" if safe == "active" else "moderate" if safe == "moderate" else "off",
        max_results=num_results,
        start_num=start_num,
        unique=unique
    )
    
    # Convert to simple URLs if not advanced mode
    if not advanced:
        return [result.url for result in results]
    return results


if __name__ == "__main__":
    from rich import print
    google = GoogleSearch(
        timeout=10,  # Optional: Set custom timeout
        proxies=None,  # Optional: Use proxies
        verify=True    # Optional: SSL verification
    )
    
    # Text Search
    print("TEXT SEARCH RESULTS:")
    text_results = google.text(
        keywords="Python programming",
        region="us",           # Optional: Region for results
        safesearch="moderate",  # Optional: "on", "moderate", "off"
        max_results=3          # Optional: Limit number of results
    )
    for result in text_results:
        print(f"Title: {result.title}")
        print(f"URL: {result.url}")
        print(f"Description: {result.description}")
        print("---")
        
    # News Search
    print("\nNEWS SEARCH RESULTS:")
    news_results = google.news(
        keywords="artificial intelligence",
        region="us",
        safesearch="moderate",
        max_results=2
    )
    for result in news_results:
        print(f"Title: {result.title}")
        print(f"URL: {result.url}")
        print(f"Description: {result.description}")
        print("---")
        
    # Search Suggestions
    print("\nSEARCH SUGGESTIONS:")
    suggestions = google.suggestions("how to")
    print(suggestions)