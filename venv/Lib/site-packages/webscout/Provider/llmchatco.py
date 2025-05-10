import requests
import json
import uuid
import re
from typing import Union, Any, Dict, Optional, Generator, List

from webscout.AIutel import Optimizers
from webscout.AIutel import Conversation
from webscout.AIutel import AwesomePrompts
from webscout.AIbase import Provider
from webscout import exceptions
from webscout.litagent import LitAgent as Lit

class LLMChatCo(Provider):
    """
    A class to interact with the LLMChat.co API
    """

    AVAILABLE_MODELS = [
        "gemini-flash-2.0",        # Default model
        "llama-4-scout",
        "gpt-4o-mini",
        # "o3-mini",
        # "claude-3-5-sonnet",
        # "deepseek-r1",
        # "claude-3-7-sonnet",
        # "deep", # deep research mode
        # "pro" # pro research mode

    ]

    def __init__(
        self,
        is_conversation: bool = True,
        max_tokens: int = 2048,
        timeout: int = 60,
        intro: str = None,
        filepath: str = None,
        update_file: bool = True,
        proxies: dict = {},
        history_offset: int = 10250,
        act: str = None,
        model: str = "gemini-flash-2.0",
        system_prompt: str = "You are a helpful assistant."
    ):
        """
        Initializes the LLMChat.co API with given parameters.
        """

        if model not in self.AVAILABLE_MODELS:
            raise ValueError(f"Invalid model: {model}. Choose from: {self.AVAILABLE_MODELS}")

        self.session = requests.Session()
        self.is_conversation = is_conversation
        self.max_tokens_to_sample = max_tokens
        self.api_endpoint = "https://llmchat.co/api/completion"
        self.timeout = timeout
        self.last_response = {}
        self.model = model
        self.system_prompt = system_prompt
        self.thread_id = str(uuid.uuid4())  # Generate a unique thread ID for conversations
        
        # Create LitAgent instance for user agent generation
        lit_agent = Lit()
        
        # Headers based on the provided request
        self.headers = {
            "Content-Type": "application/json",
            "Accept": "text/event-stream",
            "User-Agent": lit_agent.random(),
            "Accept-Language": "en-US,en;q=0.9",
            "Origin": "https://llmchat.co",
            "Referer": f"https://llmchat.co/chat/{self.thread_id}",
            "DNT": "1",
            "Sec-Fetch-Dest": "empty",
            "Sec-Fetch-Mode": "cors",
            "Sec-Fetch-Site": "same-origin"
        }

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
        self.session.proxies = proxies
        # Store message history for conversation context
        self.last_assistant_response = ""

    def parse_sse(self, data):
        """Parse Server-Sent Events data"""
        if not data or not data.strip():
            return None
            
        # Check if it's an event line
        if data.startswith('event:'):
            return {'event': data[6:].strip()}
            
        # Check if it's data
        if data.startswith('data:'):
            data_content = data[5:].strip()
            if data_content:
                try:
                    return {'data': json.loads(data_content)}
                except json.JSONDecodeError:
                    return {'data': data_content}
        
        return None

    def ask(
        self,
        prompt: str,
        stream: bool = True,  # Default to stream as the API uses SSE
        raw: bool = False,
        optimizer: str = None,
        conversationally: bool = False,
        web_search: bool = False,
    ) -> Union[Dict[str, Any], Generator[Any, None, None]]:
        """Chat with LLMChat.co with streaming capabilities"""

        conversation_prompt = self.conversation.gen_complete_prompt(prompt)
        if optimizer:
            if optimizer in self.__available_optimizers:
                conversation_prompt = getattr(Optimizers, optimizer)(
                    conversation_prompt if conversationally else prompt
                )
            else:
                raise exceptions.FailedToGenerateResponseError(
                    f"Optimizer is not one of {self.__available_optimizers}"
                )


        # Generate a unique ID for this message
        thread_item_id = ''.join(str(uuid.uuid4()).split('-'))[:20]
        messages = [
            {"role": "system", "content": self.system_prompt},
            {"role": "user", "content": prompt},
        ]
        # Prepare payload for the API request based on observed request format
        payload = {
            "mode": self.model,
            "prompt": prompt,
            "threadId": self.thread_id,
            "messages": messages,
            "mcpConfig": {},
            "threadItemId": thread_item_id,
            "parentThreadItemId": "",
            "webSearch": web_search,
            "showSuggestions": True
        }

        def for_stream():
            try:
                # Set up the streaming request
                response = self.session.post(
                    self.api_endpoint, 
                    json=payload, 
                    headers=self.headers, 
                    stream=True, 
                    timeout=self.timeout
                )
                response.raise_for_status()
                
                # Process the SSE stream
                full_response = ""
                current_event = None
                buffer = ""
                
                # Use a raw read approach to handle SSE
                for chunk in response.iter_content(chunk_size=1024, decode_unicode=False):
                    if not chunk:
                        continue
                    
                    # Decode the chunk and add to buffer
                    buffer += chunk.decode('utf-8')
                    
                    # Process complete lines in the buffer
                    while '\n' in buffer:
                        line, buffer = buffer.split('\n', 1)
                        line = line.strip()
                        
                        if not line:
                            continue
                            
                        if line.startswith('event:'):
                            current_event = line[6:].strip()
                        elif line.startswith('data:'):
                            data_content = line[5:].strip()
                            if data_content and current_event == 'answer':
                                try:
                                    json_data = json.loads(data_content)
                                    if "answer" in json_data and "text" in json_data["answer"]:
                                        text_chunk = json_data["answer"]["text"]
                                        # If there's a fullText, use it as it's more complete
                                        if json_data["answer"].get("fullText") and json_data["answer"].get("status") == "COMPLETED":
                                            text_chunk = json_data["answer"]["fullText"]
                                            
                                        # Extract only new content since last chunk
                                        new_text = text_chunk[len(full_response):]
                                        if new_text:
                                            full_response = text_chunk
                                            yield new_text if raw else dict(text=new_text)
                                except json.JSONDecodeError:
                                    continue
                            elif data_content and current_event == 'done':
                                break
                
                self.last_response.update(dict(text=full_response))
                self.last_assistant_response = full_response
                self.conversation.update_chat_history(
                    prompt, self.get_message(self.last_response)
                )

            except requests.exceptions.RequestException as e:
                raise exceptions.FailedToGenerateResponseError(f"Request failed: {e}")
            except Exception as e:
                raise exceptions.FailedToGenerateResponseError(f"Unexpected error: {str(e)}")
        
        def for_non_stream():
            full_response = ""
            try:
                for chunk in for_stream():
                    if not raw:
                        full_response += chunk.get('text', '')
                    else:
                        full_response += chunk
            except Exception as e:
                if not full_response:
                    raise exceptions.FailedToGenerateResponseError(f"Failed to get response: {str(e)}")
            
            return dict(text=full_response)

        return for_stream() if stream else for_non_stream()

    def chat(
        self,
        prompt: str,
        stream: bool = False,
        optimizer: str = None,
        conversationally: bool = False,
        web_search: bool = False,
    ) -> Union[str, Generator[str, None, None]]:
        """Generate response with streaming capabilities"""

        def for_stream():
            for response in self.ask(
                prompt, True, optimizer=optimizer, conversationally=conversationally,
                web_search=web_search
            ):
                yield self.get_message(response)

        def for_non_stream():
            return self.get_message(
                self.ask(
                    prompt,
                    False,
                    optimizer=optimizer,
                    conversationally=conversationally,
                    web_search=web_search
                )
            )

        return for_stream() if stream else for_non_stream()

    def get_message(self, response: Dict[str, Any]) -> str:
        """Retrieves message from response with validation"""
        assert isinstance(response, dict), "Response should be of dict data-type only"
        return response["text"]

if __name__ == "__main__":
    print("-" * 80)
    print(f"{'Model':<50} {'Status':<10} {'Response'}")
    print("-" * 80)
    
    # Test all available models
    working = 0
    total = len(LLMChatCo.AVAILABLE_MODELS)
    
    for model in LLMChatCo.AVAILABLE_MODELS:
        try:
            test_ai = LLMChatCo(model=model, timeout=60)
            response = test_ai.chat("Say 'Hello' in one word")
            response_text = response
            
            if response_text and len(response_text.strip()) > 0:
                status = "✓"
                # Truncate response if too long
                display_text = response_text.strip()[:50] + "..." if len(response_text.strip()) > 50 else response_text.strip()
            else:
                status = "✗"
                display_text = "Empty or invalid response"
            print(f"{model:<50} {status:<10} {display_text}")
        except Exception as e:
            print(f"{model:<50} {'✗':<10} {str(e)}")