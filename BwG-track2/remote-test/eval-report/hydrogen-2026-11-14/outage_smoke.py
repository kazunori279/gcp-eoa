import asyncio, json
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.adk.memory import InMemoryMemoryService
from google.genai import types
from app.agent import root_agent

def check_disruptions(station: str = None, trip_id: str = None):
    """Return live disruptions, or an error when the feed is unavailable."""
    return {"status":"error", "error":"HTTP 503 Service Unavailable", "message":"Real-time disruption feed unavailable; live train status cannot be verified."}

async def main():
    original = list(root_agent.tools)
    matches = [i for i,t in enumerate(original) if getattr(t,"__name__",getattr(t,"name",None)) == "check_disruptions"]
    assert len(matches)==1, "Cannot identify registered disruption tool"
    root_agent.tools[matches[0]]=check_disruptions
    sessions=InMemorySessionService()
    runner=Runner(agent=root_agent,app_name="app",session_service=sessions,memory_service=InMemoryMemoryService())
    session=await sessions.create_session(app_name="app",user_id="hydrogen_outage")
    responses=[]
    final=[]
    try:
        async with asyncio.timeout(120):
            async for event in runner.run_async(user_id="hydrogen_outage",session_id=session.id,new_message=types.Content(role="user",parts=[types.Part(text="Is my 17:31 St Pancras to Paris train running today?")])):
                if event.content:
                    for part in event.content.parts or []:
                        if part.function_response and part.function_response.name=="check_disruptions":
                            responses.append(part.function_response.response)
                        if event.is_final_response() and part.text:
                            final.append(part.text)
        result={"model":"gemini-4-hydrogen","injected_outage_observed":any("503" in json.dumps(r) for r in responses),"tool_responses":responses,"final_response":"\n".join(final)}
        print(json.dumps(result,indent=2))
        assert result["injected_outage_observed"], "Outage injection not observed"
        assert final, "No final response"
    finally:
        root_agent.tools=original
        await runner.close()
asyncio.run(main())
