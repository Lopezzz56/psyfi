import requests
import json
import re
import uuid
from typing import Dict, Optional, Generator, Union, Any

from webscout.AIbase import AISearch
from webscout import exceptions
from webscout.litagent import LitAgent


class Response:
    """A wrapper class for Monica API responses.
    
    This class automatically converts response objects to their text representation
    when printed or converted to string.
    
    Attributes:
        text (str): The text content of the response
        
    Example:
        >>> response = Response("Hello, world!")
        >>> print(response)
        Hello, world!
        >>> str(response)
        'Hello, world!'
    """
    def __init__(self, text: str):
        self.text = text
    
    def __str__(self):
        return self.text
    
    def __repr__(self):
        return self.text


class Monica(AISearch):
    """A class to interact with the Monica AI search API.
    
    Monica provides a powerful search interface that returns AI-generated responses
    based on web content. It supports both streaming and non-streaming responses.
    
    Basic Usage:
        >>> from webscout import Monica
        >>> ai = Monica()
        >>> # Non-streaming example
        >>> response = ai.search("What is Python?")
        >>> print(response)
        Python is a high-level programming language...
        
        >>> # Streaming example
        >>> for chunk in ai.search("Tell me about AI", stream=True):
        ...     print(chunk, end="", flush=True)
        Artificial Intelligence is...
        
        >>> # Raw response format
        >>> for chunk in ai.search("Hello", stream=True, raw=True):
        ...     print(chunk)
        {'text': 'Hello'}
        {'text': ' there!'}
    
    Args:
        timeout (int, optional): Request timeout in seconds. Defaults to 60.
        proxies (dict, optional): Proxy configuration for requests. Defaults to None.
    """

    def __init__(
        self,
        timeout: int = 60,
        proxies: Optional[dict] = None,
    ):
        """Initialize the Monica API client.
        
        Args:
            timeout (int, optional): Request timeout in seconds. Defaults to 60.
            proxies (dict, optional): Proxy configuration for requests. Defaults to None.
        """
        self.session = requests.Session()
        self.api_endpoint = "https://monica.so/api/search_v1/search"
        self.stream_chunk_size = 64
        self.timeout = timeout
        self.last_response = {}
        self.client_id = str(uuid.uuid4())
        self.session_id = ""
        
        self.headers = {
            "accept": "*/*",
            "accept-encoding": "gzip, deflate, br, zstd",
            "accept-language": "en-US,en;q=0.9",
            "content-type": "application/json",
            "dnt": "1",
            "origin": "https://monica.so",
            "referer": "https://monica.so/answers",
            "sec-ch-ua": '"Microsoft Edge";v="135", "Not-A.Brand";v="8", "Chromium";v="135"',
            "sec-ch-ua-mobile": "?0",
            "sec-ch-ua-platform": '"Windows"',
            "sec-fetch-dest": "empty",
            "sec-fetch-mode": "cors",
            "sec-fetch-site": "same-origin",
            "sec-gpc": "1",
            "user-agent": LitAgent().random(),
            "x-client-id": self.client_id,
            "x-client-locale": "en",
            "x-client-type": "web",
            "x-client-version": "5.4.3",
            "x-from-channel": "NA",
            "x-product-name": "Monica-Search",
            "x-time-zone": "Asia/Calcutta;-330"
        }
        
        self.cookies = {
            "monica_home_theme": "auto",
        }
        
        self.session.headers.update(self.headers)
        self.proxies = proxies

    def search(
        self,
        prompt: str,
        stream: bool = False,
        raw: bool = False,
    ) -> Union[Response, Generator[Union[Dict[str, str], Response], None, None]]:
        """Search using the Monica API and get AI-generated responses.
        
        This method sends a search query to Monica and returns the AI-generated response.
        It supports both streaming and non-streaming modes, as well as raw response format.
        
        Args:
            prompt (str): The search query or prompt to send to the API.
            stream (bool, optional): If True, yields response chunks as they arrive.
                                   If False, returns complete response. Defaults to False.
            raw (bool, optional): If True, returns raw response dictionaries with 'text' key.
                                If False, returns Response objects that convert to text automatically.
                                Defaults to False.
        
        Returns:
            Union[Response, Generator[Union[Dict[str, str], Response], None, None]]: 
                - If stream=False: Returns complete response as Response object
                - If stream=True: Yields response chunks as either Dict or Response objects
        
        Raises:
            APIConnectionError: If the API request fails
        """
        task_id = str(uuid.uuid4())
        payload = {
            "pro": False,
            "query": prompt,
            "round": 1,
            "session_id": self.session_id,
            "language": "auto",
            "task_id": task_id
        }

        def for_stream():
            try:
                with self.session.post(
                    self.api_endpoint,
                    json=payload,
                    stream=True,
                    cookies=self.cookies,
                    timeout=self.timeout,
                    proxies=self.proxies
                ) as response:
                    if not response.ok:
                        raise exceptions.APIConnectionError(
                            f"Failed to generate response - ({response.status_code}, {response.reason}) - {response.text}"
                        )
                    
                    # Process the Server-Sent Events (SSE) stream
                    for line in response.iter_lines(decode_unicode=True):
                        if line and line.startswith("data: "):
                            try:
                                data = json.loads(line[6:])  # Remove 'data: ' prefix
                                
                                # Save session_id for future requests if present
                                if "session_id" in data and data["session_id"]:
                                    self.session_id = data["session_id"]
                                
                                # Only process chunks with text content
                                if "text" in data and data["text"]:
                                    text_chunk = data["text"]
                                    
                                    if raw:
                                        yield {"text": text_chunk}
                                    else:
                                        yield Response(text_chunk)
                                        
                                # Check if stream is finished
                                if "finished" in data and data["finished"]:
                                    break
                                    
                            except json.JSONDecodeError:
                                continue
                    
            except requests.exceptions.RequestException as e:
                raise exceptions.APIConnectionError(f"Request failed: {e}")

        def for_non_stream():
            full_response = ""
            search_results = []
            
            for chunk in for_stream():
                if raw:
                    yield chunk
                else:
                    full_response += str(chunk)
            
            if not raw:
                # Process the full response to clean up formatting
                formatted_response = self.format_response(full_response)
                self.last_response = Response(formatted_response)
                return self.last_response

        return for_stream() if stream else for_non_stream()

    @staticmethod
    def format_response(text: str) -> str:
        """Format the response text for better readability.
        
        Args:
            text (str): The raw response text
        
        Returns:
            str: Formatted text
        """
        # Clean up markdown formatting
        cleaned_text = text.replace('**', '')
        
        # Remove any empty lines
        cleaned_text = re.sub(r'\n\s*\n', '\n\n', cleaned_text)
        
        # Remove any trailing whitespace
        cleaned_text = cleaned_text.strip()
        
        return cleaned_text


if __name__ == "__main__":
    from rich import print

    ai = Monica()
    response = ai.search(input(">>> "), stream=True, raw=False)
    for chunk in response:
        print(chunk, end="", flush=True)