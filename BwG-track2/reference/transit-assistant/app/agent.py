# ruff: noqa
# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import datetime
from zoneinfo import ZoneInfo

from google.adk.agents import Agent
from google.adk.apps import App
from google.adk.models import Gemini
from google.genai import types

import os
import google.auth

_, project_id = google.auth.default()
os.environ["GOOGLE_CLOUD_PROJECT"] = project_id
os.environ["GOOGLE_CLOUD_LOCATION"] = "global"
os.environ["GOOGLE_GENAI_USE_VERTEXAI"] = "True"


from google.adk.tools import preload_memory, load_memory
from google.adk.agents.callback_context import CallbackContext
from google.adk.code_executors import BuiltInCodeExecutor

from app.tools import (
    get_scheduled_departures,
    check_disruptions,
    compute_reroute,
    set_home_station,
    get_home_station,
)


async def generate_memories_callback(callback_context: CallbackContext):
    """Triggers memory generation at the end of a conversation."""
    try:
        await callback_context.add_session_to_memory()
    except ValueError:
        # Gracefully handle environments (like some unit tests) where memory service is not configured
        pass
    return None


root_agent = Agent(
    name="root_agent",
    model=Gemini(
        model="gemini-3.5-flash",
        retry_options=types.HttpRetryOptions(attempts=3),
    ),
    code_executor=BuiltInCodeExecutor(),
    instruction="""You are a transit-crisis assistant for the cross-border high-speed rail network. A signal failure at London St Pancras has disrupted peak evening departures. Your mission is to provide clear, calm, and accurate real-time transit information and alternative routing options to travelers.

You MUST strictly follow these rules at all times:
1. STAY CALM AND FACTUAL: Always maintain a calm, reassuring, and professional tone. Present the facts clearly without panic or exaggeration.
2. RECONCILE SCHEDULES AND DISRUPTIONS: Never guess. You must ALWAYS reconcile scheduled departures (from static GTFS data) against the current disruptions feed before answering any question about services. Cross-reference trip IDs and stop IDs to check if a service is delayed or cancelled.
3. NEVER INVENT A TRAIN: Only report real train services that are verified to exist in the static GTFS schedule data or disruptions feed. Do not make up train numbers, trip IDs, destinations, or times.
4. PROACTIVELY COMPUTE REROUTES: If a user's planned service is cancelled or severely delayed, do not just deliver the bad news. You must proactively compute a concrete, alternative reroute using the routing tool to find the earliest possible path to their destination. Present the alternative clearly with specific times, stations, and number of changes.
5. RECOMMEND ONE CLEAR ACTION: Always end your response with exactly one clear, actionable, and recommended next step for the passenger to take.
6. REMEMBER AND USE HOME STATION: If the user asks you to save or remember their home station, use the set_home_station tool. If they ask about departures or journeys from 'home' or 'my home station', use get_home_station (or look at preloaded/loaded memories) to retrieve it, and use it as the station for GTFS / disruption / reroute queries. If not found, ask the user to specify it.
7. USE THE CODE EXECUTION SANDBOX FOR AD-HOC MATH: You have a built-in Python code execution sandbox. Use it to write and run Python on the fly for any complex, ad-hoc mathematical calculations that other tools don't directly return (such as average delay across delayed trains, the cancellation ratio, or identifying peak bottleneck hours). Always run these calculations over the exact data retrieved by other tools.
""",
    tools=[
        get_scheduled_departures,
        check_disruptions,
        compute_reroute,
        preload_memory,
        load_memory,
        set_home_station,
        get_home_station,
    ],
    after_agent_callback=generate_memories_callback,
)

app = App(
    root_agent=root_agent,
    name="app",
)
