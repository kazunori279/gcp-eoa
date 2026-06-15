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
# TESTED REFERENCE — BwG-track2 "Rush Hour" workshop (M2 Step 4).
# Local smoke test for app/agent_runtime_app.py that catches the deploy-blockers
# WITHOUT a deploy or a live engine:
#   1. imports the runtime app (catches import/init crashes)
#   2. forces GOOGLE_CLOUD_LOCATION="global" + a dummy engine id, then asserts
#      the session/memory services resolved to a real region (catches the leak)
#   3. drives one query through async_stream_query in a single asyncio loop with
#      a FULL-PATH session_id (catches "Event loop is closed" + tests session_id
#      normalization)
# Run from the project root:  uv run python scripts/runtime_smoke.py
# ──────────────────────────────────────────────────────────────────────────
import asyncio
import os
import sys

# 1. Imports app/agent_runtime_app and builds the app object, catching import/init crashes
try:
    from app.agent_runtime_app import agent_runtime, build_session_service, build_memory_service
    print("✓ Successfully imported app/agent_runtime_app!")
except Exception as e:
    import traceback
    print("✗ Failed to import app/agent_runtime_app:")
    traceback.print_exc()
    sys.exit(1)


# 2. Asserts the session and memory services resolve to a concrete region, not "global"
print("\nTesting regional session/memory service resolution...")
os.environ["GOOGLE_CLOUD_AGENT_ENGINE_ID"] = "dummy-engine-123"
os.environ["GOOGLE_CLOUD_LOCATION"] = "global"  # deliberately simulate global leak
os.environ["GOOGLE_CLOUD_PROJECT"] = "dummy-project"

sess = build_session_service()
mem = build_memory_service()

print(f"Session Service location: {sess._location}")
print(f"Memory Service location: {mem._location}")

assert sess._location != "global", "LEAK DETECTED: Session service location is 'global'!"
assert mem._location != "global", "LEAK DETECTED: Memory service location is 'global'!"
assert sess._location is not None, "Assertion failed: Session service location is None!"
assert mem._location is not None, "Assertion failed: Memory service location is None!"
print("✓ Assertion passed: Session and Memory services successfully resolved to a concrete region, not 'global'.")


# Reset environment for local in-memory run
os.environ.pop("GOOGLE_CLOUD_AGENT_ENGINE_ID", None)
os.environ.pop("GOOGLE_CLOUD_LOCATION", None)

# Force re-initialization of our runtime services to InMemory for local smoke query execution
agent_runtime.set_up()


# 3. Drives ONE query end-to-end through async_stream_query in a single fresh asyncio loop using InMemorySessionService
async def run_smoke_query():
    print("\nDriving end-to-end smoke query...")
    query = "I'm booked on the 16:31 St Pancras to Paris service today. Is it still running, and if not, how do I still get to Paris?"
    print(f"Query: {query}")
    
    full_response = []
    try:
        # Pre-create the session using the normalized session_id to satisfy InMemorySessionService
        await agent_runtime.async_create_session(
            user_id="smoke-test-user",
            session_id="test-session-456"
        )
        print("✓ Pre-created session 'test-session-456'")

        # Pass a full path session ID (like what Gemini Enterprise sends) to test normalization
        full_path_session_id = "projects/qwiklabs-gcp/locations/us-central1/agents/123/sessions/test-session-456"
        
        async for event in agent_runtime.async_stream_query(
            message=query,
            user_id="smoke-test-user",
            session_id=full_path_session_id
        ):
            print(f"Event received: {event}")
            # Try to extract message content if available
            if isinstance(event, dict):
                # Check for standard event payload formats
                if "content" in event:
                    full_response.append(event["content"])
                elif "message" in event and isinstance(event["message"], dict):
                    content = event["message"].get("content", "")
                    if content:
                        full_response.append(content)
        
        print("\n=== FINAL RESPONSE ===")
        print("".join(str(c) for c in full_response))
        print("======================")
        print("✓ Smoke query executed successfully with no exceptions!")
    except Exception as e:
        import traceback
        print("\n✗ Smoke query failed with traceback:")
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(run_smoke_query())
