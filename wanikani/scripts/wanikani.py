#!/usr/bin/env python3
"""WaniKani API CLI — query Japanese study data."""

import os
import sys
import json
import urllib.request
import urllib.parse
import urllib.error
from datetime import datetime

API_BASE = "https://api.wanikani.com/v2"


def get_token():
    """Resolve WANIKANI_ACCESS_TOKEN from env or OpenClaw config."""
    token = os.environ.get("WANIKANI_ACCESS_TOKEN") or ""
    if not token:
        env_path = os.path.expanduser("~/.openclaw/.env")
        if os.path.isfile(env_path):
            with open(env_path, encoding="utf-8") as f:
                for line in f:
                    if line.startswith("WANIKANI_ACCESS_TOKEN="):
                        token = line.split("=", 1)[1].strip().strip('"')
                        break
    return token


def api_get(path_or_url, max_pages=1):
    """GET a WaniKani API endpoint. Supports pagination. URL must be ASCII-safe."""
    token = get_token()
    if not token:
        return {"error": "WANIKANI_ACCESS_TOKEN is not set. Set it in your environment or ~/.openclaw/.env"}

    # Ensure URL is fully ASCII (percent-encode any non-ASCII chars)
    raw_url = path_or_url if path_or_url.startswith("http") else f"{API_BASE}{path_or_url}"
    parsed = urllib.parse.urlparse(raw_url)
    safe_path = urllib.parse.quote(parsed.path, safe='/:@!$&\'()*+,;=-._~')
    safe_query = parsed.query
    url = urllib.parse.urlunparse((parsed.scheme, parsed.netloc, safe_path, parsed.params, safe_query, parsed.fragment))

    headers = {
        "Authorization": f"Bearer {token}",
        "User-Agent": "wanikani-skill/1.0",
    }

    all_data = []
    page = 0

    while url and page < max_pages:
        req = urllib.request.Request(url, headers=headers)
        try:
            with urllib.request.urlopen(req) as resp:
                body = json.loads(resp.read())
        except urllib.error.HTTPError as e:
            return {"error": f"API HTTP {e.code}: {e.reason}"}
        except urllib.error.URLError as e:
            return {"error": f"Network error: {e.reason}"}

        items = body.get("data", [])
        if isinstance(items, list):
            all_data.extend(items)
        else:
            return body

        url = body.get("pages", {}).get("next_url") or ""
        page += 1

    return {"data": all_data, "total_count": len(all_data)}


def check_err(data):
    """If data is an error dict, print it and return True."""
    if isinstance(data, dict) and "error" in data:
        print(f"❌ {data['error']}")
        return True
    return False


def fmt_date(ts):
    """Format ISO timestamp to readable date."""
    if not ts:
        return "—"
    try:
        dt = datetime.fromisoformat(ts.replace("Z", "+00:00"))
        return dt.strftime("%b %d, %Y")
    except (ValueError, AttributeError):
        return ts[:10]


def cmd_user():
    data = api_get("/user")
    if check_err(data):
        return
    d = data.get("data", {})
    sub = d.get("subscription", {})
    print(f"📊 WaniKani Profile — {d.get('username', '?')}")
    print(f"Level: {d.get('level', '?')}")
    print(f"Member since: {fmt_date(d.get('started_at'))}")
    print(f"Plan: {sub.get('type', 'free')} (max level {sub.get('max_level_granted', 3)})")


def cmd_summary():
    data = api_get("/summary")
    if check_err(data):
        return
    d = data.get("data", {})
    reviews = d.get("reviews", [])
    lessons = d.get("lessons", [])
    print("📝 Review Forecast")
    if reviews:
        n = len(reviews[0].get("subject_ids", []))
        avail = reviews[0].get("available_at", "")
        print(f"Next review batch: {n} items")
        if avail:
            try:
                dt = datetime.fromisoformat(avail.replace("Z", "+00:00"))
                print(f"Available at: {dt.strftime('%b %d, %I:%M %p')}")
            except ValueError:
                print(f"Available at: {avail}")
    else:
        print("No upcoming reviews scheduled")
    if lessons:
        n = len(lessons[0].get("subject_ids", []))
        print(f"Lessons available: {n}")


def cmd_subjects(query=None, level=None):
    if level:
        if not level.isdigit():
            print("Usage: subjects --level <N>  (N must be a number)")
            return
        data = api_get(f"/subjects?levels={level}", 3)
        if check_err(data):
            return
        results = []
        for item in data.get("data", []):
            d = item.get("data", {})
            char = d.get("characters") or "—"
            obj_type = item.get("object", "?")
            meanings = ", ".join(m["meaning"] for m in d.get("meanings", []))
            results.append(f"{char} [{obj_type}] {meanings}")
        print("\n".join(results[:50]) if results else f"No subjects at level {level}")
        return

    if query:
        # WaniKani API doesn't have a direct character search filter.
        # Fetch subjects and filter client-side.
        # Paginate across more pages to reach higher levels.
        data = api_get("/subjects", 20)
        if check_err(data):
            return

        q = query.lower()
        results = []
        seen = set()
        for item in data.get("data", []):
            d = item.get("data", {})
            char = d.get("characters", "") or ""
            slug = d.get("slug", "") or ""
            meanings = [m["meaning"].lower() for m in d.get("meanings", [])]

            # Match by: exact character, slug, or meaning keyword
            matched = (char == query) or (q in slug.lower()) or (q in meanings) or (q in char.lower())
            if not matched:
                continue

            key = f"{char}-{item.get('object', '?')}"
            if key in seen:
                continue
            seen.add(key)

            obj_type = item.get("object", "?")
            meanings_str = ", ".join(m["meaning"] for m in d.get("meanings", []))
            readings = d.get("readings", [])
            reading_str = ", ".join(
                f"{r['reading']}{'★' if r.get('primary') else ''}" for r in readings
            )
            level_num = d.get("level", "?")
            results.append(f"{char} [{obj_type}] {meanings_str}\n  Readings: {reading_str}\n  Level {level_num}")

        print("\n\n".join(results[:20]) if results else f"No subjects found for: {query}")
        return

    print("Usage: subjects <character|meaning> or subjects --level <N>")


# WaniKani SRS stages:
#   0: Locked
#   1-4: Apprentice (I–IV)
#   5-6: Guru (I–II)
#   7: Master
#   8: Enlightened
#   9: Burned
SRS_LABELS = {
    "locked": "0",
    "apprentice": "1,2,3,4",
    "guru": "5,6",
    "master": "7",
    "enlightened": "8",
    "burned": "9",
}


def cmd_assignments(stage=None):
    if stage:
        label = stage.lower()
        if label in SRS_LABELS:
            data = api_get(f"/assignments?srs_stages={SRS_LABELS[label]}", 3)
            if check_err(data):
                return
            results = []
            for item in data.get("data", [])[:20]:
                d = item.get("data", {})
                sid = d.get("subject_id", "?")
                srs = d.get("srs_stage", "?")
                unlocked = fmt_date(d.get("unlocked_at"))
                results.append(f"Subject {sid} — Stage {srs} | Unlocked: {unlocked}")
            print("\n".join(results) if results else f"No items in {label} stage")
            return

        # Maybe it's a numeric SRS stage
        if stage.isdigit():
            data = api_get(f"/assignments?srs_stages={stage}", 3)
            if check_err(data):
                return
            results = []
            for item in data.get("data", [])[:20]:
                d = item.get("data", {})
                sid = d.get("subject_id", "?")
                srs = d.get("srs_stage", "?")
                unlocked = fmt_date(d.get("unlocked_at"))
                results.append(f"Subject {sid} — Stage {srs} | Unlocked: {unlocked}")
            print("\n".join(results) if results else f"No items in stage {stage}")
            return

        print(f"Unknown stage: '{stage}'. Valid: locked, apprentice, guru, master, enlightened, burned (or 0-9)")
        return

    # No arg — show distribution
    data = api_get("/assignments", 10)
    if check_err(data):
        return
    stages = {}
    for item in data.get("data", []):
        srs = item.get("data", {}).get("srs_stage", -1)
        stages[srs] = stages.get(srs, 0) + 1
    label_names = {v: k for k, v in SRS_LABELS.items()}
    # Build per-stage labels
    stage_labels = {0: "locked", 1: "apprentice I", 2: "apprentice II", 3: "apprentice III", 4: "apprentice IV",
                    5: "guru I", 6: "guru II", 7: "master", 8: "enlightened", 9: "burned"}
    for k in sorted(stages):
        name = stage_labels.get(k, f"stage {k}")
        print(f"Stage {k} ({name}): {stages[k]} items")


def cmd_reviews(limit=10):
    data = api_get("/reviews", 1)
    if check_err(data):
        return
    results = []
    for item in data.get("data", [])[:limit]:
        d = item.get("data", {})
        rid = item.get("id", "?")
        sid = d.get("subject_id", "?")
        start = d.get("starting_srs_stage", 0)
        end = d.get("ending_srs_stage", 0)
        passed = "✅" if end > start else "❌"
        date = fmt_date(d.get("created_at"))
        results.append(f"Review #{rid}: Subject {sid} — {passed} SRS {start}→{end} ({date})")
    print("\n".join(results) if results else "No recent reviews found.")


def cmd_review_stats():
    data = api_get("/review_statistics", 3)
    if check_err(data):
        return
    items = data.get("data", [])
    if not items:
        print("No review statistics yet — need more reviews!")
        return

    scores = [
        i["data"]["percentage_correct"]
        for i in items if i.get("data", {}).get("percentage_correct") is not None
    ]
    if not scores:
        print("No review statistics yet.")
        return

    avg = sum(scores) / len(scores)
    print(f"📈 Review Statistics")
    print(f"Items with stats: {len(scores)}")
    print(f"Average accuracy: {avg:.0f}%")

    struggling = [
        i for i in items
        if i.get("data", {}).get("percentage_correct") is not None
        and i["data"]["percentage_correct"] < 80
    ]
    for s in sorted(struggling, key=lambda x: x["data"]["percentage_correct"])[:10]:
        d = s["data"]
        sid = d.get("subject_id") or s.get("id", "?")
        mistakes = d.get("meaning_incorrect", 0) + d.get("reading_incorrect", 0)
        print(f"⚠️ Subject {sid}: {d['percentage_correct']}% accuracy ({mistakes} mistakes)")


def cmd_levels():
    data = api_get("/level_progressions")
    if check_err(data):
        return
    results = []
    for item in data.get("data", []):
        d = item.get("data", {})
        lvl = d.get("level", "?")
        unlocked = fmt_date(d.get("unlocked_at"))
        passed = fmt_date(d.get("passed_at"))
        completed = fmt_date(d.get("completed_at"))
        results.append(f"Level {lvl}: {unlocked} → {passed} → {completed}")
    print("\n".join(results) if results else "No level data yet.")


def cmd_leeches():
    data = api_get("/review_statistics", 5)
    if check_err(data):
        return
    items = data.get("data", [])
    leeches = [
        i for i in items
        if i.get("data", {}).get("percentage_correct") is not None
        and i["data"]["percentage_correct"] < 70
    ]
    if not leeches:
        print("No leeches found — doing great! 🎉")
        return

    leeches.sort(key=lambda x: x["data"]["percentage_correct"])
    for s in leeches[:10]:
        d = s["data"]
        sid = d.get("subject_id") or s.get("id", "?")
        pct = d["percentage_correct"]
        mistakes = d.get("meaning_incorrect", 0) + d.get("reading_incorrect", 0)
        print(f"🐛 Subject {sid}: {pct}% — {mistakes} mistakes total")


def cmd_help():
    print("""WaniKani API CLI

Commands:
  user|me              Profile info (level, username, plan)
  summary|forecast     Today's review forecast
  subjects <char|slug> Look up a kanji/vocab/radical
  subjects --level <N> List subjects at a level
  assignments|srs      SRS stage distribution
  assignments <stage>  Filter by stage (locked|apprentice|guru|master|enlightened|burned|0-9)
  reviews [limit]      Recent review history
  review-stats|acc     Accuracy statistics
  levels|progression   Level progress timeline
  leeches|struggles    Subjects below 70% accuracy""")


def main():
    args = sys.argv[1:]
    if not args:
        cmd_help()
        return

    cmd = args[0]

    if cmd in ("user", "me"):
        cmd_user()
    elif cmd in ("summary", "forecast"):
        cmd_summary()
    elif cmd in ("subjects", "kanji", "vocab"):
        level = None
        query_parts = []
        i = 1
        while i < len(args):
            if args[i] == "--level":
                i += 1
                if i < len(args) and args[i].isdigit():
                    level = args[i]
                else:
                    print("Usage: subjects --level <N>  (N must be a number)")
                    return
            else:
                query_parts.append(args[i])
            i += 1
        cmd_subjects(query=" ".join(query_parts) if query_parts else None, level=level)
    elif cmd in ("assignments", "srs"):
        cmd_assignments(args[1] if len(args) > 1 else None)
    elif cmd in ("reviews", "history"):
        limit = int(args[1]) if len(args) > 1 and args[1].isdigit() else 10
        cmd_reviews(limit)
    elif cmd in ("review-stats", "accuracy", "acc"):
        cmd_review_stats()
    elif cmd in ("levels", "progression"):
        cmd_levels()
    elif cmd in ("leeches", "struggles"):
        cmd_leeches()
    else:
        cmd_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
