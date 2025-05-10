import requests
import json
import uuid
import time
import hashlib
from typing import Any, Dict, Optional, Generator, Union

from webscout.AIutel import Optimizers
from webscout.AIutel import Conversation
from webscout.AIutel import AwesomePrompts, sanitize_stream
from webscout.AIbase import Provider, AsyncProvider
from webscout import exceptions
from webscout.litagent import LitAgent

class Aitopia(Provider):
    """
    A class to interact with the Aitopia API with LitAgent user-agent.
    """

    AVAILABLE_MODELS = [
        "Claude 3 Haiku",
        "GPT-4o Mini",
        "Gemini 1.5 Flash",
        "Llama 3.1 70B"
    ]

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
        model: str = "Claude 3 Haiku",
        browser: str = "chrome"
    ):
        """Initializes the Aitopia API client."""
        if model not in self.AVAILABLE_MODELS:
            raise ValueError(f"Invalid model: {model}. Choose from: {self.AVAILABLE_MODELS}")
            
        self.url = "https://extensions.aitopia.ai/ai/send"
        
        # Initialize LitAgent for user agent generation
        self.agent = LitAgent()
        # Use fingerprinting to create a consistent browser identity
        self.fingerprint = self.agent.generate_fingerprint(browser)
        
        # Use the fingerprint for headers
        self.headers = {
            "accept": "text/plain",
            "accept-language": self.fingerprint["accept_language"],
            "content-type": "text/plain;charset=UTF-8",
            "dnt": "1",
            "origin": "https://chat.aitopia.ai",
            "priority": "u=1, i",
            "referer": "https://chat.aitopia.ai/",
            "sec-ch-ua": self.fingerprint["sec_ch_ua"] or '"Chromium";v="134", "Not:A-Brand";v="24", "Microsoft Edge";v="134"',
            "sec-ch-ua-mobile": "?0",
            "sec-ch-ua-platform": f'"{self.fingerprint["platform"]}"',
            "sec-fetch-dest": "empty",
            "sec-fetch-mode": "cors",
            "sec-fetch-site": "same-site",
            "user-agent": self.fingerprint["user_agent"]
        }
        
        self.session = requests.Session()
        self.session.headers.update(self.headers)
        self.session.proxies.update(proxies)

        self.is_conversation = is_conversation
        self.max_tokens_to_sample = max_tokens
        self.timeout = timeout
        self.last_response = {}
        self.model = model

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
            "accept-language": self.fingerprint["accept_language"],
            "sec-ch-ua": self.fingerprint["sec_ch_ua"] or self.headers["sec-ch-ua"],
            "sec-ch-ua-platform": f'"{self.fingerprint["platform"]}"',
            "user-agent": self.fingerprint["user_agent"],
        })
        
        # Update session headers
        for header, value in self.headers.items():
            self.session.headers[header] = value
        
        return self.fingerprint

    def generate_uuid_search(self):
        """Generate a UUID and convert to base64-like string."""
        uuid_str = str(uuid.uuid4())
        return uuid_str.replace('-', '')

    def generate_hopekey(self):
        """Generate a random string and hash it."""
        random_str = str(uuid.uuid4()) + str(time.time())
        return hashlib.md5(random_str.encode()).hexdigest()

    def ask(
        self,
        prompt: str,
        stream: bool = False,
        raw: bool = False,
        optimizer: str = None,
        conversationally: bool = False,
    ) -> Union[Dict[str, Any], Generator]:
        conversation_prompt = self.conversation.gen_complete_prompt(prompt)
        if optimizer:
            if optimizer in self.__available_optimizers:
                conversation_prompt = getattr(Optimizers, optimizer)(
                    conversation_prompt if conversationally else prompt
                )
            else:
                raise Exception(f"Optimizer is not one of {self.__available_optimizers}")

        # Generate hopekey and update headers
        hopekey = self.generate_hopekey()
        self.headers["hopekey"] = hopekey
        
        # Default history if none provided
        history = [
            {
                "item": "Hello, how can I help you today?",
                "role": "assistant",
                # "model": "GPT-4o Mini"
            }
        ]
        
        # Generate current timestamp for chat_id
        current_time = int(time.time() * 1000)
        
        # Request payload
        payload = {
            "history": history,
            "text": conversation_prompt,
            "model": self.model,
            "stream": stream,
            "uuid_search": self.generate_uuid_search(),
            "mode": "ai_chat",
            "prompt_mode": False,
            "extra_key": "__all",
            "extra_data": {"prompt_mode": False},
            "chat_id": current_time,
            "language_detail": {
                "lang_code": "en",
                "name": "English",
                "title": "English"
            },
            "is_continue": False,
            "lang_code": "en"
        }

        def for_stream():
            try:
                with requests.post(self.url, headers=self.headers, json=payload, stream=True, timeout=self.timeout) as response:
                    if response.status_code != 200:
                        raise exceptions.FailedToGenerateResponseError(
                            f"Request failed with status code {response.status_code}"
                        )
                    
                    streaming_text = ""
                    for line in response.iter_lines():
                        if line:
                            line = line.decode('utf-8')
                            if line.startswith('data: '):
                                data = line[6:]
                                if data == '[DONE]':
                                    break
                                try:
                                    json_data = json.loads(data)
                                    
                                    # Handle Claude 3 Haiku response format
                                    if "delta" in json_data and "text" in json_data["delta"]:
                                        content = json_data["delta"]["text"]
                                        if content:
                                            streaming_text += content
                                            resp = dict(text=content)
                                            yield resp if raw else resp
                                    # Handle GPT-4o Mini response format
                                    elif "choices" in json_data and "0" in json_data["choices"]:
                                        content = json_data["choices"]["0"]["delta"].get("content", "")
                                        if content:
                                            streaming_text += content
                                            resp = dict(text=content)
                                            yield resp if raw else resp
                                except json.JSONDecodeError:
                                    continue
                    
                    self.last_response = {"text": streaming_text}
                    self.conversation.update_chat_history(prompt, streaming_text)
                    
            except requests.RequestException as e:
                raise exceptions.FailedToGenerateResponseError(f"Request failed: {str(e)}")

        def for_non_stream():
            try:
                response = requests.post(self.url, headers=self.headers, json=payload, timeout=self.timeout)
                if response.status_code != 200:
                    raise exceptions.FailedToGenerateResponseError(
                        f"Request failed with status code {response.status_code}"
                    )

                response_data = response.json()
                if 'choices' in response_data and len(response_data['choices']) > 0:
                    content = response_data['choices'][0].get('message', {}).get('content', '')
                    self.last_response = {"text": content}
                    self.conversation.update_chat_history(prompt, content)
                    return {"text": content}
                else:
                    raise exceptions.FailedToGenerateResponseError("No response content found")
            except Exception as e:
                raise exceptions.FailedToGenerateResponseError(f"Request failed: {e}")

        return for_stream() if stream else for_non_stream()

    def chat(
        self,
        prompt: str,
        stream: bool = False,
        optimizer: str = None,
        conversationally: bool = False,
    ) -> Union[str, Generator[str, None, None]]:
        def for_stream():
            for response in self.ask(prompt, True, optimizer=optimizer, conversationally=conversationally):
                yield self.get_message(response)
        def for_non_stream():
            return self.get_message(
                self.ask(prompt, False, optimizer=optimizer, conversationally=conversationally)
            )
        return for_stream() if stream else for_non_stream()

    def get_message(self, response: dict) -> str:
        assert isinstance(response, dict), "Response should be of dict data-type only"
        return response["text"]

if __name__ == "__main__":
    print("-" * 80)
    print(f"{'Model':<50} {'Status':<10} {'Response'}")
    print("-" * 80)

    for model in Aitopia.AVAILABLE_MODELS:
        try:
            test_ai = Aitopia(model=model, timeout=60)
            response = test_ai.chat("Say 'Hello' in one word", stream=True)
            response_text = ""
            for chunk in response:
                response_text += chunk
            
            if response_text and len(response_text.strip()) > 0:
                status = "✓"
                # Clean and truncate response
                clean_text = response_text.strip().encode('utf-8', errors='ignore').decode('utf-8')
                display_text = clean_text[:50] + "..." if len(clean_text) > 50 else clean_text
            else:
                status = "✗"
                display_text = "Empty or invalid response"
            print(f"\r{model:<50} {status:<10} {display_text}")
        except Exception as e:
            print(f"\r{model:<50} {'✗':<10} {str(e)}")