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
#
# ──────────────────────────────────────────────────────────────────────────
# TESTED REFERENCE — BwG-track2 "Rush Hour" workshop (M2).
# Drop-in replacement for the file `agents-cli scaffold enhance
# --deployment-target agent_runtime` generates. The three deploy-time issues below
# are limitations of the file that command produces in the agents-cli version this
# workshop was validated against (see "Reference version" date) — they are NOT bugs
# in the participant's own agent code, and are expected to be fixed upstream (see the
# TODO), at which point this drop-in becomes unnecessary. Until then this file handles
# all three — search for the matching "ISSUE #n" markers to see where — plus the
# Gemini Enterprise session_id contract:
#   • ISSUE #1 (import / init crash): Session/Memory services fall back to the
#     InMemory implementations when no engine id is set, so importing this module
#     and running set_up() never crash off-cloud (local runs + runtime_smoke.py).
#   • ISSUE #2 ("Invalid Session resource name"): Session/Memory are pinned to a
#     concrete region — never "global" — so the session resource path is valid.
#   • ISSUE #3 ("Event loop is closed"): a fresh GenAI client is built per request
#     so a client bound to an already-closed event loop is never reused.
#   • session_id normalization across streaming + structured methods (M5 portal).
# Validated locally via runtime_smoke.py (import + region assert + end-to-end
# async_stream_query). Assumes this workshop's project shape: app/agent.py
# exposes `app`, and app/app_utils/{telemetry,typing}.py exist (from scaffold).
#
# Reference version: validated 2026-06-15. agents-cli is installed unpinned (the M0
#   `uvx google-agents-cli setup` pulls latest), so there is no fixed version; the
#   most recent resolved build was agents-cli 0.4.0 (2026-06-17). If a newer release
#   fixes the three issues below, re-verify and retire this drop-in.
# MAINTENANCE: this file is a drop-in over what `scaffold enhance` generates. If the
#   scaffold's project shape changes (e.g. app/agent.py stops exposing `app`, or
#   app/app_utils/* moves), refresh this file from a fresh scaffold, re-apply the four
#   fixes above, and re-run runtime_smoke.py before re-publishing.
# TODO(upstream): fold these four fixes into `agents-cli scaffold enhance
#   --deployment-target agent_runtime` so the generated file is correct out of the box
#   and M2 Step 1 needs no curl at all.
# ──────────────────────────────────────────────────────────────────────────
import logging
import os
from typing import Any

import vertexai
from dotenv import load_dotenv
from google.adk.artifacts import GcsArtifactService, InMemoryArtifactService
from google.cloud import logging as google_cloud_logging
from vertexai.agent_engines.templates.adk import AdkApp

from app.agent import app as adk_app
from app.app_utils.telemetry import setup_telemetry
from app.app_utils.typing import Feedback

# Load environment variables from .env file at runtime
load_dotenv()


def _normalize_session_id(sid: str | None) -> str | None:
    return sid.rstrip("/").split("/")[-1] if sid else sid


def build_session_service():
    # On Agent Runtime an engine id is present → use the managed Vertex AI service.
    engine_id = os.environ.get("GOOGLE_CLOUD_AGENT_ENGINE_ID")
    if engine_id:
        from google.adk.sessions.vertex_ai_session_service import VertexAiSessionService
        project = os.environ.get("GOOGLE_CLOUD_PROJECT") or os.environ.get("PROJECT_ID")
        region = os.environ.get("GOOGLE_CLOUD_AGENT_ENGINE_LOCATION") or os.environ.get("GOOGLE_CLOUD_REGION") or "us-east1"
        # ISSUE #2 ("Invalid Session resource name"): the service MUST resolve to a
        # concrete region. A "global" (or empty) location yields a malformed session
        # resource path that the deployed runtime rejects — clamp it to a real region.
        if not region or region.lower() == "global":
            region = "us-east1"
        return VertexAiSessionService(
            project=project,
            location=region,
            agent_engine_id=engine_id,
        )
    # ISSUE #1 (import / init crash): no engine id locally (and in runtime_smoke.py),
    # so fall back to the in-memory service instead of constructing a Vertex client
    # with no engine — this keeps import + set_up() from crashing off-cloud.
    from google.adk.sessions.in_memory_session_service import InMemorySessionService
    return InMemorySessionService()


def build_memory_service():
    engine_id = os.environ.get("GOOGLE_CLOUD_AGENT_ENGINE_ID")
    if engine_id:
        from google.adk.memory.vertex_ai_memory_bank_service import VertexAiMemoryBankService
        project = os.environ.get("GOOGLE_CLOUD_PROJECT") or os.environ.get("PROJECT_ID")
        region = os.environ.get("GOOGLE_CLOUD_AGENT_ENGINE_LOCATION") or os.environ.get("GOOGLE_CLOUD_REGION") or "us-east1"
        # ISSUE #2 ("Invalid Session resource name"): Memory Bank is regional too —
        # never let the location be "global"/empty or the resource path is invalid.
        if not region or region.lower() == "global":
            region = "us-east1"
        return VertexAiMemoryBankService(
            project=project,
            location=region,
            agent_engine_id=engine_id,
        )
    # ISSUE #1 (import / init crash): fall back to the in-memory Memory Bank when no
    # engine id is set, so local runs / runtime_smoke.py import and initialize cleanly.
    from google.adk.memory.in_memory_memory_service import InMemoryMemoryService
    return InMemoryMemoryService()


class AgentEngineApp(AdkApp):
    def set_up(self) -> None:
        """Initialize the agent engine app with logging and telemetry."""
        vertexai.init()
        setup_telemetry()
        super().set_up()
        logging.basicConfig(level=logging.INFO)
        logging_client = google_cloud_logging.Client()
        self.logger = logging_client.logger(__name__)
        if gemini_location:
            os.environ["GOOGLE_CLOUD_LOCATION"] = gemini_location

    def register_feedback(self, feedback: dict[str, Any]) -> None:
        """Collect and log feedback."""
        feedback_obj = Feedback.model_validate(feedback)
        self.logger.log_struct(feedback_obj.model_dump(), severity="INFO")

    def register_operations(self) -> dict[str, list[str]]:
        """Registers the operations of the Agent."""
        operations = super().register_operations()
        operations[""] = [*operations.get("", []), "register_feedback"]
        return operations

    def clone(self) -> "AgentEngineApp":
        """Returns a clone of the Agent Runtime application."""
        return self

    def _clear_cached_clients(self) -> None:
        """Clears cached GenAI clients to ensure a fresh client is used per request/thread."""
        # ISSUE #3 ("Event loop is closed"): the GenAI client caches a connection bound
        # to the asyncio loop that created it. Agent Runtime serves each request on a
        # fresh loop, so a reused client raises "Event loop is closed" on the 2nd+
        # request. Dropping the cached clients forces a new client (and loop binding)
        # per request. This is called at the top of every streaming entrypoint below.
        adk_app = self._tmpl_attrs.get("app")
        if adk_app and hasattr(adk_app, "root_agent"):
            model = getattr(adk_app.root_agent, "model", None)
            if model:
                for key in ["api_client", "_live_api_client"]:
                    if hasattr(model, "__dict__") and key in model.__dict__:
                        del model.__dict__[key]

    async def streaming_agent_run_with_events(self, request_json: str):
        """Streams responses asynchronously, clearing cached clients and normalizing session_id."""
        self._clear_cached_clients()
        import json
        try:
            req = json.loads(request_json)
            if "session_id" in req:
                req["session_id"] = _normalize_session_id(req["session_id"])
            if "sessionId" in req:
                req["sessionId"] = _normalize_session_id(req["sessionId"])
            new_json = json.dumps(req)
        except Exception:
            new_json = request_json

        async for ev in super().streaming_agent_run_with_events(new_json):
            yield ev

    async def async_stream_query(
        self,
        *,
        message: Any,
        user_id: str,
        session_id: str | None = None,
        **kwargs,
    ):
        """Streams responses asynchronously, clearing cached clients and normalizing session_id."""
        self._clear_cached_clients()
        normalized_sid = _normalize_session_id(session_id)
        async for ev in super().async_stream_query(
            message=message,
            user_id=user_id,
            session_id=normalized_sid,
            **kwargs,
        ):
            yield ev

    async def async_get_session(
        self,
        *,
        user_id: str,
        session_id: str,
        **kwargs,
    ):
        """Gets a session, normalizing session_id."""
        normalized_sid = _normalize_session_id(session_id)
        return await super().async_get_session(
            user_id=user_id,
            session_id=normalized_sid,
            **kwargs,
        )

    async def async_delete_session(
        self,
        *,
        user_id: str,
        session_id: str,
        **kwargs,
    ):
        """Deletes a session, normalizing session_id."""
        normalized_sid = _normalize_session_id(session_id)
        return await super().async_delete_session(
            user_id=user_id,
            session_id=normalized_sid,
            **kwargs,
        )


gemini_location = os.environ.get("GOOGLE_CLOUD_LOCATION")
logs_bucket_name = os.environ.get("LOGS_BUCKET_NAME")
agent_runtime = AgentEngineApp(
    app=adk_app,
    artifact_service_builder=lambda: (
        GcsArtifactService(bucket_name=logs_bucket_name)
        if logs_bucket_name
        else InMemoryArtifactService()
    ),
    session_service_builder=build_session_service,
    memory_service_builder=build_memory_service,
)
