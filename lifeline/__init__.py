"""
LifeLine - Personal Memory & Timeline Assistant
Built with OpenAI Agents SDK
"""

__version__ = "0.1.0"

from .agent import create_lifeline_agent
from .models import EventQuery, EventSummary, TimelineEvent

__all__ = [
    "create_lifeline_agent",
    "TimelineEvent",
    "EventQuery",
    "EventSummary",
]
