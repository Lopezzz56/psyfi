"""
TempMail Package - Temporary Email Generation Functionality
Part of Webscout Extra tools
"""

from .base import (
    TempMailProvider, 
    AsyncTempMailProvider, 
    get_random_email, 
    get_disposable_email,
    get_provider
)
from .mail_tm import MailTM, MailTMAsync
from .temp_mail_io import TempMailIO, TempMailIOAsync

__all__ = [
    'TempMailProvider',
    'AsyncTempMailProvider', 
    'MailTM',
    'MailTMAsync',
    'TempMailIO',
    'TempMailIOAsync',
    'get_random_email',
    'get_disposable_email',
    'get_provider'
]