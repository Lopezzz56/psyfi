import requests
import json
from datetime import datetime
from typing import Any, Dict, Optional, Generator, Union

from webscout.AIutel import Optimizers
from webscout.AIutel import Conversation
from webscout.AIutel import AwesomePrompts
from webscout.AIbase import Provider
from webscout import exceptions
from webscout.litagent import LitAgent

class SearchChatAI(Provider):
    """
    A class to interact with the SearchChatAI API.
    """
    AVAILABLE_MODELS = ["gpt-4o-mini-2024-07-18"]
    def __init__(
        self,
        is_conversation: bool = True,
        max_tokens: int = 2049,
        timeout: int = 30,
        intro: str = None,
        filepath: str = None,
        update_file: bool = True,
        proxies: dict = {},
        history_offset: int = 10250,
        act: str = None,
        system_prompt: str = "You are a helpful assistant."
    ):
        """Initializes the SearchChatAI API client."""
        self.url = "https://search-chat.ai/api/chat-test-stop.php"
        self.timeout = timeout
        self.is_conversation = is_conversation
        self.max_tokens_to_sample = max_tokens
        self.last_response = {}
        self.system_prompt = system_prompt
        
        # Initialize LitAgent for user agent generation
        self.agent = LitAgent()
        # Use fingerprinting to create a consistent browser identity
        self.fingerprint = self.agent.generate_fingerprint("chrome")
        
        # Use the fingerprint for headers
        self.headers = {
            "Accept": self.fingerprint["accept"],
            "Accept-Encoding": "gzip, deflate, br, zstd",
            "Accept-Language": self.fingerprint["accept_language"],
            "Content-Type": "application/json",
            "Origin": "https://search-chat.ai",
            "Referer": "https://search-chat.ai/platform/?v2=2",
            "Sec-Fetch-Dest": "empty",
            "Sec-Fetch-Mode": "cors",
            "Sec-Fetch-Site": "same-origin",
            "Sec-CH-UA": self.fingerprint["sec_ch_ua"] or '"Not)A;Brand";v="99", "Microsoft Edge";v="127", "Chromium";v="127"',
            "Sec-CH-UA-Mobile": "?0",
            "Sec-CH-UA-Platform": f'"{self.fingerprint["platform"]}"',
            "User-Agent": self.fingerprint["user_agent"],
        }
        
        self.session = requests.Session()
        self.session.headers.update(self.headers)
        self.session.proxies.update(proxies)

        self.__available_optimizers = (
            method
            for method in dir(Optimizers)
            if callable(getattr(Optimizers, method)) and not method.startswith("__")
        )
        Conversation.intro = (
            AwesomePrompts().get_act(
                act, raise_not_found=True, default=None, case_insensitive=True
            )
            if act
            else intro or Conversation.intro
        )

        self.conversation = Conversation(
            is_conversation, self.max_tokens_to_sample, filepath, update_file
        )
        self.conversation.history_offset = history_offset

    def refresh_identity(self, browser: str = None):
        """
        Refreshes the browser identity fingerprint.
        
        Args:
            browser: Specific browser to use for the new fingerprint
        """
        browser = browser or self.fingerprint.get("browser_type", "chrome")
        self.fingerprint = self.agent.generate_fingerprint(browser)
        
        # Update headers with new fingerprint
        self.headers.update({
            "Accept": self.fingerprint["accept"],
            "Accept-Language": self.fingerprint["accept_language"],
            "Sec-CH-UA": self.fingerprint["sec_ch_ua"] or self.headers["Sec-CH-UA"],
            "Sec-CH-UA-Platform": f'"{self.fingerprint["platform"]}"',
            "User-Agent": self.fingerprint["user_agent"],
        })
        
        # Update session headers
        for header, value in self.headers.items():
            self.session.headers[header] = value
        
        return self.fingerprint

    def ask(
        self,
        prompt: str,
        stream: bool = False,
        raw: bool = False,
        optimizer: str = None,
        conversationally: bool = False,
    ) -> Union[Dict[str, Any], Generator]:
        """
        Send a message to the API and get the response.
        
        Args:
            prompt: The message to send
            stream: Whether to stream the response
            raw: Whether to return raw response
            optimizer: The optimizer to use
            conversationally: Whether to use conversation history
            
        Returns:
            Either a dictionary with the response or a generator for streaming
        """
        conversation_prompt = self.conversation.gen_complete_prompt(prompt)
        if optimizer:
            if optimizer in self.__available_optimizers:
                conversation_prompt = getattr(Optimizers, optimizer)(
                    conversation_prompt if conversationally else prompt
                )
            else:
                raise Exception(f"Optimizer is not one of {self.__available_optimizers}")

        payload = {
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": conversation_prompt
                        }
                    ],
                    "timestamp": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.%fZ")
                }
            ]
        }

        def for_stream():
            try:
                with self.session.post(
                    self.url,
                    json=payload,
                    stream=True,
                    timeout=self.timeout
                ) as response:
                    if response.status_code != 200:
                        raise exceptions.FailedToGenerateResponseError(
                            f"Request failed with status code {response.status_code}"
                        )
                    
                    streaming_text = ""
                    for line in response.iter_lines():
                        if line:
                            line = line.decode('utf-8')
                            if line.startswith('data: '):
                                data_str = line[6:]  # Remove 'data: ' prefix
                                
                                if data_str == '[DONE]':
                                    break
                                    
                                try:
                                    data = json.loads(data_str)
                                    if "choices" in data and len(data["choices"]) > 0:
                                        delta = data["choices"][0].get("delta", {})
                                        if "content" in delta:
                                            content = delta["content"]
                                            streaming_text += content
                                            resp = dict(text=content)
                                            yield resp if raw else content
                                except json.JSONDecodeError:
                                    continue
                    
                    self.last_response = {"text": streaming_text}
                    self.conversation.update_chat_history(prompt, streaming_text)
                    
            except requests.RequestException as e:
                raise exceptions.FailedToGenerateResponseError(f"Request failed: {str(e)}")

        def for_non_stream():
            try:
                response = self.session.post(
                    self.url,
                    json=payload,
                    stream=True,  # Keep streaming enabled
                    timeout=self.timeout
                )
                if response.status_code != 200:
                    raise exceptions.FailedToGenerateResponseError(
                        f"Request failed with status code {response.status_code}"
                    )
                
                full_text = ""
                for line in response.iter_lines():
                    if line:
                        line = line.decode('utf-8')
                        if line.startswith('data: '):
                            data_str = line[6:]  # Remove 'data: ' prefix
                            
                            if data_str == '[DONE]':
                                break
                                
                            try:
                                data = json.loads(data_str)
                                if "choices" in data and len(data["choices"]) > 0:
                                    delta = data["choices"][0].get("delta", {})
                                    if "content" in delta:
                                        content = delta["content"]
                                        full_text += content
                            except json.JSONDecodeError:
                                continue
                
                if full_text:
                    self.last_response = {"text": full_text}
                    self.conversation.update_chat_history(prompt, full_text)
                    return {"text": full_text}
                else:
                    raise exceptions.FailedToGenerateResponseError("No response content found")
                    
            except Exception as e:
                raise exceptions.FailedToGenerateResponseError(f"Request failed: {str(e)}")

        return for_stream() if stream else for_non_stream()

    def chat(
        self,
        prompt: str,
        stream: bool = False,
        optimizer: str = None,
        conversationally: bool = False,
    ) -> Union[str, Generator[str, None, None]]:
        """
        Chat with the API.
        
        Args:
            prompt: The message to send
            stream: Whether to stream the response
            optimizer: The optimizer to use
            conversationally: Whether to use conversation history
            
        Returns:
            Either a string response or a generator for streaming
        """
        def for_stream():
            for response in self.ask(prompt, True, optimizer=optimizer, conversationally=conversationally):
                yield self.get_message(response)
                
        def for_non_stream():
            return self.get_message(
                self.ask(prompt, False, optimizer=optimizer, conversationally=conversationally)
            )
            
        return for_stream() if stream else for_non_stream()

    def get_message(self, response: dict) -> str:
        """Extract the message from the response."""
        assert isinstance(response, dict), "Response should be of dict data-type only"
        return response["text"]

if __name__ == "__main__":
    print("-" * 80)
    print(f"{'Status':<10} {'Response'}")
    print("-" * 80)

    try:
        test_ai = SearchChatAI(timeout=60)
        response = test_ai.chat("Say 'Hello' in one word")
        response_text = response
        
        if response_text and len(response_text.strip()) > 0:
            status = "✓"
            # Truncate response if too long
            display_text = response_text.strip()[:50] + "..." if len(response_text.strip()) > 50 else response_text.strip()
        else:
            status = "✗"
            display_text = "Empty or invalid response"
        print(f"{status:<10} {display_text}")
    except Exception as e:
        print(f"{'✗':<10} {str(e)}") 