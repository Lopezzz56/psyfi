"""
>>> from litprinter import litprint
>>> from litprinter import lit
>>> from litprinter import install, uninstall
>>>
>>> litprint("Hello, world!")
LIT -> [__main__.py:1] in () >>> Hello, world!
>>>
>>> def my_function():
...    lit(1, 2, 3)
>>> my_function()
LIT -> [__main__.py:4] in my_function() >>> 1, 2, 3
>>> install()
>>> ic("This is now the builtins.ic()")
LIT -> [__main__.py:7] in () >>> This is now the builtins.ic()
>>> uninstall()

This module provides enhanced print and logging functionalities for Python,
allowing developers to debug their code with style and precision. It
includes the litprint and lit functions for debugging, log for logging, and
install/uninstall functions for integration into the builtins module.
It also handles colorizing output and provides different styles and customizable
options.

LITPRINTER is inspired by the icecream package and provides similar functionality
with additional features:
- Variable inspection with expression display
- Return value handling for inline usage
- Support for custom formatters for specific data types
- Execution context tracking
- Rich-like colorized output with multiple themes (JARVIS, RICH, MODERN, NEON, CYBERPUNK)
- Better JSON formatting with indent=2 by default
- Advanced pretty printing for complex data structures with smart truncation
- Clickable file paths in supported terminals and editors (VSCode compatible)
- Enhanced visual formatting with better spacing and separators
- Special formatters for common types (Exception, bytes, set, frozenset, etc.)
- Smart object introspection for custom classes
- Logging capabilities with timestamp and log levels
"""

# Try to import from the standalone litprinter package first
# If it's not installed
try:
    import litprinter
    # If standalone package is found, re-export all its components
    from litprinter import litprint, lit, log, ic, install, uninstall
    from litprinter import LITPrintDebugger, argumentToString
    from litprinter import JARVIS, RICH, MODERN, NEON, CYBERPUNK, create_custom_style
    from litprinter import traceback   
    # For compatibility with icecream
    enable = litprinter.enable
    disable = litprinter.disable
    
except ImportError:
    # Raise a more informative error when litprinter is not installed
    raise ImportError(
        "The 'litprinter' package is required but not installed. "
        "Please install it using: pip install litprinter"
    ) from None