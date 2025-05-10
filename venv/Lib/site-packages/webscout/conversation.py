import os
import json
import logging
from typing import Optional, Dict, List, Any, TypedDict, Callable, TypeVar, Union

T = TypeVar('T')


class FunctionCall(TypedDict):
    """Type for a function call."""
    name: str
    arguments: Dict[str, Any]


class ToolDefinition(TypedDict):
    """Type for a tool definition."""
    type: str
    function: Dict[str, Any]


class FunctionCallData(TypedDict, total=False):
    """Type for function call data"""
    tool_calls: List[FunctionCall]
    error: str


class Fn:
    """
    Represents a function (tool) that the agent can call.
    """
    def __init__(self, name: str, description: str, parameters: Dict[str, str]) -> None:
        self.name: str = name
        self.description: str = description
        self.parameters: Dict[str, str] = parameters


def tools(func: Callable[..., T]) -> Callable[..., T]:
    """Decorator to mark a function as a tool and automatically convert it."""
    func._is_tool = True  # type: ignore
    return func


class Conversation:
    """Handles prompt generation based on history and maintains chat context.
    
    This class is responsible for managing chat conversations, including:
    - Maintaining chat history
    - Loading/saving conversations from/to files
    - Generating prompts based on context
    - Managing token limits and history pruning
    - Supporting tool calling functionality
    
    Examples:
        >>> chat = Conversation(max_tokens=500)
        >>> chat.add_message("user", "Hello!")
        >>> chat.add_message("llm", "Hi there!")
        >>> prompt = chat.gen_complete_prompt("What's up?")
    """

    intro = (
        "You're a helpful Large Language Model assistant. "
        "Respond directly to the user's questions or use tools when appropriate."
    )

    def __init__(
        self,
        status: bool = True,
        max_tokens: int = 600,
        filepath: Optional[str] = None,
        update_file: bool = True,
        tools: Optional[List[Fn]] = None,
    ):
        """Initialize a new Conversation manager.

        Args:
            status (bool): Flag to control history tracking. Defaults to True.
            max_tokens (int): Maximum tokens for completion response. Defaults to 600.
            filepath (str, optional): Path to save/load conversation history. Defaults to None.
            update_file (bool): Whether to append new messages to file. Defaults to True.
            tools (List[Fn], optional): List of tools available for the conversation. Defaults to None.

        Examples:
            >>> chat = Conversation(max_tokens=500)
            >>> chat = Conversation(filepath="chat_history.txt")
        """
        self.status = status
        self.max_tokens_to_sample = max_tokens
        self.chat_history = ""  # Initialize as empty string
        self.history_format = "\nUser : %(user)s\nLLM :%(llm)s"
        self.tool_history_format = "\nUser : %(user)s\nLLM : [Tool Call: %(tool)s]\nTool : %(result)s"
        self.file = filepath
        self.update_file = update_file
        self.history_offset = 10250
        self.prompt_allowance = 10
        self.tools = tools or []
        
        if filepath:
            self.load_conversation(filepath, False)

    def load_conversation(self, filepath: str, exists: bool = True) -> None:
        """Load conversation history from a text file.

        Args:
            filepath (str): Path to the history file
            exists (bool): Flag for file availability. Defaults to True.

        Raises:
            AssertionError: If filepath is not str or file doesn't exist
        """
        assert isinstance(
            filepath, str
        ), f"Filepath needs to be of str datatype not {type(filepath)}"
        assert (
            os.path.isfile(filepath) if exists else True
        ), f"File '{filepath}' does not exist"

        if not os.path.isfile(filepath):
            with open(filepath, "w", encoding="utf-8") as fh:
                fh.write(self.intro)
        else:
            with open(filepath, encoding="utf-8") as fh:
                file_contents = fh.readlines()
                if file_contents:
                    self.intro = file_contents[0]  # First line is intro
                    self.chat_history = "\n".join(file_contents[1:])
    
    def __trim_chat_history(self, chat_history: str, intro: str) -> str:
        """Keep the chat history fresh by trimming it when it gets too long! 

        This method makes sure we don't exceed our token limits by:
        - Calculating total length (intro + history)
        - Trimming older messages if needed
        - Keeping the convo smooth and within limits

        Args:
            chat_history (str): The current chat history to trim
            intro (str): The conversation's intro/system prompt

        Returns:
            str: The trimmed chat history, ready to use! 

        Examples:
            >>> chat = Conversation(max_tokens=500)
            >>> trimmed = chat._Conversation__trim_chat_history("Hello! Hi!", "Intro")
        """
        len_of_intro = len(intro)
        len_of_chat_history = len(chat_history)
        total = self.max_tokens_to_sample + len_of_intro + len_of_chat_history

        if total > self.history_offset:
            truncate_at = (total - self.history_offset) + self.prompt_allowance
            trimmed_chat_history = chat_history[truncate_at:]
            return "... " + trimmed_chat_history
        return chat_history

    def gen_complete_prompt(self, prompt: str, intro: Optional[str] = None) -> str:
        """Generate a complete prompt that's ready to go! 

        This method:
        - Combines the intro, history, and new prompt
        - Adds tools information if available
        - Trims history if needed
        - Keeps everything organized and flowing

        Args:
            prompt (str): Your message to add to the chat
            intro (str, optional): Custom intro to use. Default: None (uses class intro)

        Returns:
            str: The complete conversation prompt, ready for the LLM! 

        Examples:
            >>> chat = Conversation()
            >>> prompt = chat.gen_complete_prompt("What's good?")
        """
        if not self.status:
            return prompt

        intro = intro or self.intro or (
            '''You are a helpful and versatile AI assistant. Your goal is to provide concise and informative responses directly to user queries.  Use available tools in correct format to enhance responses or execute actions as needed.
''')
        
        # Add tool information if tools are available
        tools_description = self.get_tools_description()
        if tools_description:
            try:
                from datetime import datetime
                date_str = f"Current date: {datetime.now().strftime('%d %b %Y')}"
            except:
                date_str = ""
                
            intro = (f'''
                {intro}

{date_str}

**CORE PROTOCOL:**

Your goal is to assist the user effectively. Analyze each query and choose one of two response modes:

**1. Tool Mode:**
   - **When:** If the query requires external data, calculations, or functions listed under AVAILABLE TOOLS (e.g., web search, current info).
   - **Action:** Output *ONLY* the complete JSON tool call, exactly matching the TOOL FORMAT below, enclosed in `<tool_call>` and `</tool_call>` tags.
   - **CRITICAL:** Absolutely NO text, whitespace, or characters before `<tool_call>` or after `</tool_call>`. The output *must* start with `<tool_call>` and end with `</tool_call>`.
   - **Example (Output is *only* this block):**
     ```json
     <tool_call>
     {{
         "name": "search",
         "arguments": {{ "query": "latest population of Tokyo" }}
     }}
     </tool_call>
     ```

**2. Conversational Mode:**
   - **When:** If the query can be answered using your internal knowledge, is creative, or conversational.
   - **Action:** Respond directly, clearly, and concisely.
   - **Example:** *User:* "Explain photosynthesis." *Assistant:* "Photosynthesis is how plants use sunlight, water, and carbon dioxide to create their food (glucose) and release oxygen."

**ABSOLUTE PROHIBITIONS:**
   - **NEVER Explain Tool Use:** Don't say you're using a tool, which one, or why.
   - **NEVER Describe JSON/Tags:** Do not mention `tool_call`, JSON structure, or parameters.
   - **NEVER Apologize for Tools:** No need to say sorry for lacking direct info.
   - **NEVER Mix Text and Tool Calls:** Tool calls must be standalone.

**Be concise and relevant in all responses.**

**AVAILABLE TOOLS:**
{tools_description}

**TOOL FORMAT (Use Exactly):**
<tool_call>
{{
    "name": "tool_name",
    "arguments": {{
        "param": "value"
        /* Add other parameters as needed */
    }}
}}
</tool_call>

**Summary Check:**
1. Tool needed? -> Output *only* the JSON in tags.
2. No tool needed? -> Respond directly and conversationally.
3. Avoid *all* prohibited explanations/text.
''')
        
        incomplete_chat_history = self.chat_history + self.history_format % {
            "user": prompt,
            "llm": ""
        }
        complete_prompt = intro + self.__trim_chat_history(incomplete_chat_history, intro)
        return complete_prompt

    def update_chat_history(
        self, prompt: str, response: str, force: bool = False
    ) -> None:
        """Keep the conversation flowing by updating the chat history! 

        This method:
        - Adds new messages to the history
        - Updates the file if needed
        - Keeps everything organized

        Args:
            prompt (str): Your message to add
            response (str): The LLM's response
            force (bool): Force update even if history is off. Default: False

        Examples:
            >>> chat = Conversation()
            >>> chat.update_chat_history("Hi!", "Hello there!")
        """
        if not self.status and not force:
            return

        new_history = self.history_format % {"user": prompt, "llm": response}
        
        if self.file and self.update_file:
            # Create file if it doesn't exist
            if not os.path.exists(self.file):
                with open(self.file, "w", encoding="utf-8") as fh:
                    fh.write(self.intro + "\n")
            
            # Append new history
            with open(self.file, "a", encoding="utf-8") as fh:
                fh.write(new_history)
        
        self.chat_history += new_history
        # logger.info(f"Chat history updated with prompt: {prompt}")

    def update_chat_history_with_tool(
        self, prompt: str, tool_name: str, tool_result: str, force: bool = False
    ) -> None:
        """Update chat history with a tool call and its result.

        This method:
        - Adds tool call interaction to the history
        - Updates the file if needed
        - Maintains the conversation flow with tools

        Args:
            prompt (str): The user's message that triggered the tool call
            tool_name (str): Name of the tool that was called
            tool_result (str): Result returned by the tool
            force (bool): Force update even if history is off. Default: False

        Examples:
            >>> chat = Conversation()
            >>> chat.update_chat_history_with_tool("What's the weather?", "weather_tool", "It's sunny, 75°F")
        """
        if not self.status and not force:
            return

        new_history = self.tool_history_format % {
            "user": prompt,
            "tool": tool_name,
            "result": tool_result
        }
        
        if self.file and self.update_file:
            # Create file if it doesn't exist
            if not os.path.exists(self.file):
                with open(self.file, "w", encoding="utf-8") as fh:
                    fh.write(self.intro + "\n")
            
            # Append new history
            with open(self.file, "a", encoding="utf-8") as fh:
                fh.write(new_history)
        
        self.chat_history += new_history

    def add_message(self, role: str, content: str) -> None:
        """Add a new message to the chat - simple and clean! 

        This method:
        - Validates the message role
        - Adds the message to history
        - Updates file if needed

        Args:
            role (str): Who's sending? ('user', 'llm', 'tool', or 'reasoning')
            content (str): What's the message?

        Examples:
            >>> chat = Conversation()
            >>> chat.add_message("user", "Hey there!")
            >>> chat.add_message("llm", "Hi! How can I help?")
        """
        if not self.validate_message(role, content):
            raise ValueError("Invalid message role or content")

        role_formats = {
            "user": "User",
            "llm": "LLM",
            "tool": "Tool",
            "reasoning": "Reasoning"
        }

        if role in role_formats:
            self.chat_history += f"\n{role_formats[role]} : {content}"
        else:
            raise ValueError(f"Invalid role: {role}. Must be one of {list(role_formats.keys())}")

    #     # Enhanced logging for message addition
    #     logger.info(f"Added message from {role}: {content}")
    #     logging.info(f"Message added: {role}: {content}")

    def validate_message(self, role: str, content: str) -> bool:
        """Validate the message role and content."""
        valid_roles = {            'user', 'llm', 'tool', 'reasoning', 'function_call'        }
        if role not in valid_roles:
            logging.error(f"Invalid role: {role}")
            return False
        if not content:
            logging.error("Content cannot be empty.")
            return False
        return True

    def _parse_function_call(self, response: str) -> FunctionCallData:
        """Parse a function call from the LLM's response.
        
        Args:
            response (str): The LLM's response containing a function call
            
        Returns:
            FunctionCallData: Parsed function call data or error
        """
        try:
            # First try the standard format with square brackets: <tool_call>[...]</tool_call>
            start_tag: str = "<tool_call>["
            end_tag: str = "]</tool_call>"
            start_idx: int = response.find(start_tag)
            end_idx: int = response.rfind(end_tag)

            # If not found, try the alternate format: <tool_call>\n{...}\n</tool_call>
            if start_idx == -1 or end_idx == -1 or end_idx <= start_idx:
                start_tag = "<tool_call>"
                end_tag = "</tool_call>"
                start_idx = response.find(start_tag)
                end_idx = response.rfind(end_tag)
                
                if start_idx == -1 or end_idx == -1 or end_idx <= start_idx:
                    raise ValueError("No valid <tool_call> JSON structure found in the response.")
                
                # Extract JSON content - for the format without brackets
                json_str: str = response[start_idx + len(start_tag):end_idx].strip()
                
                # Try to parse the JSON directly
                try:
                    parsed_response: Any = json.loads(json_str)
                    if isinstance(parsed_response, dict):
                        return {"tool_calls": [parsed_response]}
                    else:
                        raise ValueError("Invalid JSON structure in tool call.")
                except json.JSONDecodeError:
                    # If direct parsing failed, try to extract just the JSON object
                    import re
                    json_pattern = re.search(r'\{[\s\S]*\}', json_str)
                    if json_pattern:
                        parsed_response = json.loads(json_pattern.group(0))
                        return {"tool_calls": [parsed_response]}
                    raise
            else:
                # Extract JSON content - for the format with brackets
                json_str: str = response[start_idx + len(start_tag):end_idx].strip()
                parsed_response: Any = json.loads(json_str)
                
                if isinstance(parsed_response, list):
                    return {"tool_calls": parsed_response}
                elif isinstance(parsed_response, dict):
                    return {"tool_calls": [parsed_response]}
                else:
                    raise ValueError("<tool_call> should contain a list or a dictionary of tool calls.")

        except (ValueError, json.JSONDecodeError) as e:
            logging.error(f"Error parsing function call: %s", e)
            return {"error": str(e)}

    def execute_function(self, function_call_data: FunctionCallData) -> str:
        """Execute a function call and return the result.
        
        Args:
            function_call_data (FunctionCallData): The function call data
            
        Returns:
            str: Result of the function execution
        """
        tool_calls: Optional[List[FunctionCall]] = function_call_data.get("tool_calls")

        if not tool_calls or not isinstance(tool_calls, list):
            return "Invalid tool_calls format."
        
        results: List[str] = []
        for tool_call in tool_calls:
            function_name: str = tool_call.get("name")
            arguments: Dict[str, Any] = tool_call.get("arguments", {})

            if not function_name or not isinstance(arguments, dict):
                results.append(f"Invalid tool call: {tool_call}")
                continue

            # Here you would implement the actual execution logic for each tool
            # For demonstration, we'll return a placeholder response
            results.append(f"Executed {function_name} with arguments {arguments}")

        return "; ".join(results)
        
    def _convert_fns_to_tools(self, fns: Optional[List[Fn]]) -> List[ToolDefinition]:
        """Convert functions to tool definitions for the LLM.
        
        Args:
            fns (Optional[List[Fn]]): List of function definitions
            
        Returns:
            List[ToolDefinition]: List of tool definitions
        """
        if not fns:
            return []
        
        tools: List[ToolDefinition] = []
        for fn in fns:
            tool: ToolDefinition = {
                "type": "function",
                "function": {
                    "name": fn.name,
                    "description": fn.description,
                    "parameters": {
                        "type": "object",
                        "properties": {
                            param_name: {
                                "type": param_type,
                                "description": f"The {param_name} parameter"
                            } for param_name, param_type in fn.parameters.items()
                        },
                        "required": list(fn.parameters.keys())
                    }
                }
            }
            tools.append(tool)
        return tools
        
    def get_tools_description(self) -> str:
        """Get a formatted string of available tools for the intro prompt.
        
        Returns:
            str: Formatted tools description
        """
        if not self.tools:
            return ""
            
        tools_desc = []
        for fn in self.tools:
            params_desc = ", ".join([f"{name}: {typ}" for name, typ in fn.parameters.items()])
            tools_desc.append(f"- {fn.name}: {fn.description} (Parameters: {params_desc})")
            
        return "\n".join(tools_desc)

    def handle_tool_response(self, response: str) -> Dict[str, Any]:
        """Process a response that might contain a tool call.
        
        This method:
        - Checks if the response contains a tool call
        - Parses and executes the tool call if present
        - Returns the appropriate result
        
        Args:
            response (str): The LLM's response
            
        Returns:
            Dict[str, Any]: Result containing 'is_tool_call', 'result', and 'original_response'
        """
        # Check if response contains a tool call
        if "<tool_call>" in response:
            function_call_data = self._parse_function_call(response)
            
            if "error" in function_call_data:
                return {
                    "is_tool_call": True, 
                    "success": False,
                    "result": function_call_data["error"],
                    "original_response": response
                }
                
            # Execute the function call
            result = self.execute_function(function_call_data)
            
            # Add the result to chat history as a tool message
            self.add_message("tool", result)
            
            return {
                "is_tool_call": True,
                "success": True,
                "result": result,
                "tool_calls": function_call_data.get("tool_calls", []),
                "original_response": response
            }
        
        return {
            "is_tool_call": False,
            "result": response,
            "original_response": response
        }


