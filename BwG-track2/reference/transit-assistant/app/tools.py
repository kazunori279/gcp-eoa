import os
import json
from typing import Dict, Any, List, Optional
from pathlib import Path
from google.adk.tools import ToolContext

# Data Path Resolution relative to the app directory
APP_DIR = Path(__file__).parent
DATA_DIR = APP_DIR / "data"
GTFS_DIR = DATA_DIR / "gtfs"
DISRUPTIONS_FILE = DATA_DIR / "disruptions.json"
CALENDAR_DATES_FILE = GTFS_DIR / "calendar_dates.txt"

_gtfs_cache: Dict[str, Any] = {}

def normalize_station(station_str: str) -> str:
    """Normalizes a station name string to its standard stop_id."""
    s = station_str.lower().strip()
    if "pancras" in s or "london" in s or "stp" in s:
        return "st_pancras_international"
    if "paris" in s or "nord" in s:
        return "paris_nord"
    if "brussels" in s or "bruxelles" in s or "midi" in s:
        return "bruxelles_midi"
    if "amsterdam" in s:
        return "amsterdam_centraal"
    if "rotterdam" in s:
        return "rotterdam_centraal"
    if "koln" in s or "cologne" in s or "köln" in s:
        return "koln_hbf"
    if "antwerp" in s or "antwerpen" in s:
        return "antwerpen_centraal"
    if "liege" in s or "liège" in s:
        return "liege_guillemins"
    if "lille" in s:
        return "lille_europe"
    if "dortmund" in s:
        return "dortmund_hbf"
    if "duisburg" in s:
        return "duisburg_hbf"
    if "dusseldorf" in s or "düsseldorf" in s:
        return "dusseldorf_hbf"
    if "essen" in s:
        return "essen_hbf"
    if "marne" in s or "chessy" in s:
        return "marne_la_vallee_chessy"
    if "roissy" in s or "cdg" in s:
        return "roissy_airport_cdg_2"
    if "schiphol" in s:
        return "schiphol_airport"
    if "aachen" in s:
        return "aachen_hbf"
    
    # Substring matching in known stops
    stops = {
        "st_pancras_international": "St-Pancras-International",
        "paris_nord": "Paris-Nord",
        "bruxelles_midi": "Bruxelles-Midi",
        "amsterdam_centraal": "Amsterdam-Centraal",
        "rotterdam_centraal": "Rotterdam-Centraal",
        "koln_hbf": "Köln Hbf",
        "aachen_hbf": "Aachen Hbf",
        "antwerpen_centraal": "Antwerpen-Centraal",
        "liege_guillemins": "Liege-Guillemins",
        "lille_europe": "Lille-Europe",
        "dortmund_hbf": "Dortmund Hbf",
        "duisburg_hbf": "Duisburg Hbf",
        "dusseldorf_hbf": "Düsseldorf Hbf",
        "essen_hbf": "Essen Hbf",
        "marne_la_vallee_chessy": "Marne-la-Vallée-Chessy",
        "roissy_airport_cdg_2": "Roissy-Airport-CDG 2",
        "schiphol_airport": "Schiphol Airport"
    }
    for stop_id, stop_name in stops.items():
        if s in stop_id.lower() or s in stop_name.lower():
            return stop_id
    return station_str


def load_gtfs_data() -> Dict[str, Any]:
    """Loads and caches GTFS static schedule data."""
    global _gtfs_cache
    if _gtfs_cache:
        return _gtfs_cache
    
    # 1. Load stops.txt
    stops = {}
    stops_file = GTFS_DIR / "stops.txt"
    with open(stops_file, "r") as f:
        next(f)
        for line in f:
            parts = line.strip().split(",")
            if len(parts) >= 3:
                stops[parts[0]] = parts[2]
                
    # 2. Load routes.txt
    routes = {}
    routes_file = GTFS_DIR / "routes.txt"
    with open(routes_file, "r") as f:
        next(f)
        for line in f:
            parts = line.strip().split(",")
            if len(parts) >= 4:
                routes[parts[0]] = parts[3]
                
    # 3. Load trips.txt
    trips = {}
    trips_file = GTFS_DIR / "trips.txt"
    with open(trips_file, "r") as f:
        next(f)
        for line in f:
            parts = line.strip().split(",")
            if len(parts) >= 4:
                trips[parts[2]] = {
                    "route_id": parts[0],
                    "service_id": parts[1],
                    "trip_headsign": parts[3]
                }
                
    # 4. Load stop_times.txt
    trip_stops = {}
    stop_times_file = GTFS_DIR / "stop_times.txt"
    with open(stop_times_file, "r") as f:
        next(f)
        for line in f:
            parts = line.strip().split(",")
            if len(parts) >= 5:
                t_id = parts[0]
                arr = parts[1]
                dep = parts[2]
                s_id = parts[3]
                seq = int(parts[4])
                if t_id not in trip_stops:
                    trip_stops[t_id] = []
                trip_stops[t_id].append({
                    "stop_id": s_id,
                    "arrival_time": arr,
                    "departure_time": dep,
                    "stop_sequence": seq
                })
    
    for t_id, s_list in trip_stops.items():
        s_list.sort(key=lambda x: x["stop_sequence"])
        
    _gtfs_cache["stops"] = stops
    _gtfs_cache["routes"] = routes
    _gtfs_cache["trips"] = trips
    _gtfs_cache["trip_stops"] = trip_stops
    return _gtfs_cache


def get_scheduled_departures(station: str, start_time: str, end_time: str, date: str = "2026-07-15") -> Dict[str, Any]:
    """Queries the static GTFS data to list departures from a given station within a time window.
    
    Args:
        station: The origin station name (e.g. 'St Pancras', 'Paris-Nord') or stop_id.
        start_time: The start of the time window in HH:MM or HH:MM:SS format (e.g. '15:00').
        end_time: The end of the time window in HH:MM or HH:MM:SS format (e.g. '19:30').
        date: The travel date in YYYY-MM-DD format (defaults to '2026-07-15').
        
    Returns:
        A dictionary containing a list of scheduled departures.
    """
    try:
        cache = load_gtfs_data()
        stops = cache["stops"]
        routes = cache["routes"]
        trips = cache["trips"]
        trip_stops = cache["trip_stops"]
    except Exception as e:
        return {"status": "error", "message": f"Failed to load static schedule data: {str(e)}"}
        
    base_stop_id = normalize_station(station)
    matching_stop_ids = [sid for sid in stops if sid.startswith(base_stop_id)]
    if not matching_stop_ids:
        return {"status": "error", "message": f"Station '{station}' could not be resolved."}
        
    def norm_time(t: str) -> str:
        t = t.strip()
        if len(t) == 5:
            return t + ":00"
        return t
        
    start_t = norm_time(start_time)
    end_t = norm_time(end_time)
    
    date_normalized = date.replace("-", "").strip()
    active_services = set()
    
    try:
        with open(CALENDAR_DATES_FILE, "r") as f:
            next(f)
            for line in f:
                parts = line.strip().split(",")
                if len(parts) >= 3:
                    s_id, d, exc = parts[0], parts[1], parts[2]
                    if d == date_normalized and exc == "1":
                        active_services.add(s_id)
    except Exception as e:
        return {"status": "error", "message": f"Failed to load service calendar: {str(e)}"}
                    
    departures = []
    
    for t_id, s_list in trip_stops.items():
        trip_info = trips.get(t_id)
        if not trip_info:
            continue
            
        if trip_info["service_id"] not in active_services:
            continue
            
        for stop_entry in s_list:
            if stop_entry["stop_id"] in matching_stop_ids:
                dep_time = stop_entry["departure_time"]
                if start_t <= dep_time <= end_t:
                    dest_stop_id = s_list[-1]["stop_id"]
                    dest_name = stops.get(dest_stop_id, trip_info["trip_headsign"])
                    
                    r_id = trip_info["route_id"]
                    r_name = routes.get(r_id, r_id)
                    
                    departures.append({
                        "trip_id": t_id,
                        "route_id": r_id,
                        "route": r_name,
                        "origin": stops.get(stop_entry["stop_id"], stop_entry["stop_id"]),
                        "destination": dest_name,
                        "departure_time": dep_time,
                        "destination_arrival_time": s_list[-1]["arrival_time"],
                        "train_number": t_id.split("-")[0]
                    })
                    break
                    
    departures.sort(key=lambda x: x["departure_time"])
    
    return {
        "status": "success",
        "station": station,
        "base_stop_id": base_stop_id,
        "date": date,
        "departures": departures
    }


def check_disruptions(station: Optional[str] = None, trip_id: Optional[str] = None) -> Dict[str, Any]:
    """Reads disruptions.json and returns affected services, delays, and cancellations.
    
    Args:
        station: Optional station name or stop_id to filter disruptions (e.g. 'St Pancras', 'Paris-Nord').
        trip_id: Optional trip ID (e.g. '9032-0715') to check for a specific service.
        
    Returns:
        A dictionary detailing current disruptions, affected trips, unaffected routes, and passenger advice.
    """
    if not DISRUPTIONS_FILE.exists():
        return {"status": "error", "message": "Disruption feed not found."}
        
    try:
        with open(DISRUPTIONS_FILE, "r") as f:
            data = json.load(f)
    except Exception as e:
        return {"status": "error", "message": f"Failed to read disruption feed: {str(e)}"}
        
    affected_trips = data.get("affected_trips", [])
    
    if trip_id:
        affected_trips = [t for t in affected_trips if trip_id.lower() in t["trip_id"].lower()]
        
    if station:
        base_stop_id = normalize_station(station)
        filtered_trips = []
        for t in affected_trips:
            origin = t.get("origin", "").lower()
            dest = t.get("destination", "").lower()
            aff_stops = [s.lower() for s in t.get("affected_stops", [])]
            
            if (base_stop_id in origin or 
                base_stop_id in dest or 
                any(base_stop_id in s for s in aff_stops)):
                filtered_trips.append(t)
        affected_trips = filtered_trips
        
    return {
        "status": "success",
        "disruption_id": data.get("disruption_id"),
        "cause": data.get("cause"),
        "location": data.get("location"),
        "severity": data.get("severity"),
        "summary": data.get("summary"),
        "affected_trips": affected_trips,
        "unaffected_routes": data.get("unaffected_routes", []),
        "passenger_advice": data.get("passenger_advice", "")
    }


def compute_reroute(origin: str, destination: str, departure_after: str, date: str = "2026-07-15") -> Dict[str, Any]:
    """Computes an alternative route from origin to destination avoiding cancelled services.
    
    Args:
        origin: Origin station name or stop_id.
        destination: Destination station name or stop_id.
        departure_after: Earliest departure time in HH:MM or HH:MM:SS.
        date: Travel date in YYYY-MM-DD (defaults to '2026-07-15').
        
    Returns:
        A dictionary containing the recommended itinerary or alternative routes.
    """
    import collections
    
    try:
        cache = load_gtfs_data()
        stops = cache["stops"]
        routes = cache["routes"]
        trips = cache["trips"]
        trip_stops = cache["trip_stops"]
    except Exception as e:
        return {"status": "error", "message": f"Failed to load schedule data: {str(e)}"}
        
    origin_base = normalize_station(origin)
    dest_base = normalize_station(destination)
    
    if origin_base == dest_base:
        return {"status": "error", "message": "Origin and destination are the same."}
        
    def norm_time(t: str) -> str:
        t = t.strip()
        if len(t) == 5:
            return t + ":00"
        return t
        
    def add_minutes(time_str: str, minutes: int) -> str:
        parts = time_str.split(":")
        h = int(parts[0])
        m = int(parts[1])
        s = int(parts[2]) if len(parts) > 2 else 0
        total_seconds = h * 3600 + m * 60 + s + minutes * 60
        new_h = (total_seconds // 3600) % 24
        new_m = (total_seconds % 3600) // 60
        new_s = total_seconds % 60
        return f"{new_h:02d}:{new_m:02d}:{new_s:02d}"
        
    start_time = norm_time(departure_after)
    
    # Load disruptions
    disruptions = {}
    if DISRUPTIONS_FILE.exists():
        try:
            with open(DISRUPTIONS_FILE, "r") as f:
                disp_data = json.load(f)
                for t in disp_data.get("affected_trips", []):
                    disruptions[t["trip_id"]] = {
                        "status": t["status"],
                        "delay_minutes": t.get("delay_minutes") or 0
                    }
        except Exception as e:
            return {"status": "error", "message": f"Failed to load disruptions: {str(e)}"}
                
    # Load active services
    active_services = set()
    try:
        with open(CALENDAR_DATES_FILE, "r") as f:
            next(f)
            for line in f:
                parts = line.strip().split(",")
                if len(parts) >= 3:
                    s_id, d, exc = parts[0], parts[1], parts[2]
                    if d == date.replace("-", "").strip() and exc == "1":
                        active_services.add(s_id)
    except Exception as e:
        return {"status": "error", "message": f"Failed to load service calendar: {str(e)}"}
                    
    connections = []
    
    for t_id, s_list in trip_stops.items():
        trip_info = trips.get(t_id)
        if not trip_info:
            continue
            
        if trip_info["service_id"] not in active_services:
            continue
            
        disp = disruptions.get(t_id)
        if disp and disp["status"] == "cancelled":
            continue
            
        delay = disp["delay_minutes"] if disp else 0
        
        adjusted_stops = []
        for stop_entry in s_list:
            stop_id = stop_entry["stop_id"]
            base_id = normalize_station(stop_id)
            dep = add_minutes(stop_entry["departure_time"], delay)
            arr = add_minutes(stop_entry["arrival_time"], delay)
            adjusted_stops.append({
                "base_id": base_id,
                "departure_time": dep,
                "arrival_time": arr
            })
            
        for i in range(len(adjusted_stops)):
            for j in range(i + 1, len(adjusted_stops)):
                connections.append({
                    "trip_id": t_id,
                    "train_number": t_id.split("-")[0],
                    "from_station": adjusted_stops[i]["base_id"],
                    "to_station": adjusted_stops[j]["base_id"],
                    "departure_time": adjusted_stops[i]["departure_time"],
                    "arrival_time": adjusted_stops[j]["arrival_time"]
                })
                
    queue = collections.deque([(origin_base, start_time, [])])
    
    best_arrival = {origin_base: start_time}
    best_paths = {origin_base: []}
    
    while queue:
        curr_station, curr_time, curr_path = queue.popleft()
        
        if best_arrival.get(curr_station, "99:99:99") < curr_time:
            continue
            
        for conn in connections:
            if conn["from_station"] == curr_station:
                min_wait = 0
                if curr_path and curr_path[-1]["trip_id"] != conn["trip_id"]:
                    min_wait = 5
                    
                allowed_dep_time = add_minutes(curr_time, min_wait)
                
                if conn["departure_time"] >= allowed_dep_time:
                    dest = conn["to_station"]
                    arr_time = conn["arrival_time"]
                    
                    if dest not in best_arrival or arr_time < best_arrival[dest]:
                        best_arrival[dest] = arr_time
                        new_segment = {
                            "trip_id": conn["trip_id"],
                            "train_number": conn["train_number"],
                            "from": stops.get(conn["from_station"], conn["from_station"]),
                            "to": stops.get(conn["to_station"], conn["to_station"]),
                            "departure_time": conn["departure_time"],
                            "arrival_time": conn["arrival_time"]
                        }
                        best_paths[dest] = curr_path + [new_segment]
                        queue.append((dest, arr_time, best_paths[dest]))
                        
    if dest_base not in best_arrival:
        return {
            "status": "no_route",
            "message": f"No alternative route found from '{stops.get(origin_base, origin)}' to '{stops.get(dest_base, destination)}' departing after {departure_after}."
        }
        
    itinerary = best_paths[dest_base]
    
    changes = 0
    if len(itinerary) > 1:
        for k in range(1, len(itinerary)):
            if itinerary[k]["trip_id"] != itinerary[k-1]["trip_id"]:
                changes += 1
                
    return {
        "status": "success",
        "origin": stops.get(origin_base, origin),
        "destination": stops.get(dest_base, destination),
        "departure_after": departure_after,
        "arrival_time": best_arrival[dest_base],
        "changes": changes,
        "itinerary": itinerary
    }


def set_home_station(station: str, tool_context: ToolContext) -> Dict[str, Any]:
    """Sets the user's home station in their short-term session state.
    
    Args:
        station: The name of the home station (e.g. 'St Pancras', 'Paris-Nord').
        tool_context: The ADK context used to access and modify session state.
    """
    normalized = normalize_station(station)
    tool_context.state["home_station"] = normalized
    return {
        "status": "success",
        "message": f"Home station has been set to '{normalized}' in the session state.",
        "home_station": normalized
    }


def get_home_station(tool_context: ToolContext) -> Dict[str, Any]:
    """Retrieves the user's home station from their short-term session state.
    
    Args:
        tool_context: The ADK context used to access session state.
    """
    station = tool_context.state.get("home_station")
    if station:
        return {
            "status": "success",
            "home_station": station
        }
    else:
        return {
            "status": "not_found",
            "message": "Home station is not set in the short-term session state."
        }

