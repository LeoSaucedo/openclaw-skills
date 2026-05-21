#!/usr/bin/env python3
"""WaniKani API CLI — query Japanese study data."""

import os
import sys
import json
import urllib.request
import urllib.parse
import urllib.error
from datetime import datetime, timezone

API_BASE = "https://api.wanikani.com/v2"


def get_token():
    """Resolve WANIKANI_ACCESS_TOKEN from env or OpenClaw config."""
    token = os.environ.get("WANIKANI_ACCESS_TOKEN") or ""
    if not token:
        env_path = os.path.expanduser("~/.openclaw/.env")
        if os.path.isfile(env_path):
            for line in open(env_path):
                if line.startswith("WANIKANI_ACCESS_TOKEN="):
                    token = line.split("=", 1)[1].strip().strip('"')
                    break
    return token


def api_get(path_or_url, max_pages=1):
    """GET a WaniKani API endpoint. Supports pagination. URL must be ASCII-safe."""
    token = get_token()
    if not token:
        print('{"error":"WANIKANI_ACCESS_TOKEN not set"}', file=sys.stderr)
        sys.exit(1)

    # Ensure URL is fully ASCII (percent-encode any non-ASCII chars)
    raw_url = path_or_url if path_or_url.startswith("http") else f"{API_BASE}{path_or_url}"
    parsed = urllib.parse.urlparse(raw_url)
    safe_path = urllib.parse.quote(parsed.path, safe='/:@!$&\'()*+,;=-._~')
    safe_query = parsed.query  # already percent-encoded from quote() calls
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
            return {"error": f"HTTP {e.code}: {e.reason}"}
        except urllib.error.URLError as e:
            return {"error": str(e.reason)}

        items = body.get("data", [])
        if isinstance(items, list):
            all_data.extend(items)
        else:
            # Single resource — return directly
            return body

        url = body.get("pages", {}).get("next_url") or ""
        page += 1

    return {"data": all_data, "total_count": len(all_data)}


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
    if "error" in data:
        return data["error"]
    d = data.get("data", {})
    sub = d.get("subscription", {})
    lines = [
        f"📊 WaniKani Profile — {d.get('username', '?')}",
        f"Level: {d.get('level', '?')}",
        f"Member since: {fmt_date(d.get('started_at'))}",
        f"Plan: {sub.get('type', 'free')} (max level {sub.get('max_level_granted', 3)})",
    ]
    return "\n".join(lines)


def cmd_summary():
    data = api_get("/summary")
    if "error" in data:
        return data["error"]
    d = data.get("data", {})
    reviews = d.get("reviews", [])
    lessons = d.get("lessons", [])

    lines = ["📝 Review Forecast"]
    if reviews:
        n = len(reviews[0].get("subject_ids", []))
        avail = reviews[0].get("available_at", "")
        lines.append(f"Next review batch: {n} items")
        if avail:
            try:
                dt = datetime.fromisoformat(avail.replace("Z", "+00:00"))
                lines.append(f"Available at: {dt.strftime('%b %d, %I:%M %p')}")
            except ValueError:
                lines.append(f"Available at: {avail}")
    else:
        lines.append("No upcoming reviews scheduled")

    if lessons:
        n = len(lessons[0].get("subject_ids", []))
        lines.append(f"Lessons available: {n}")
    return "\n".join(lines)


def cmd_subjects(query=None, level=None):
    if level:
        data = api_get(f"/subjects?filter[levels]={level}", 3)
        results = []
        for item in data.get("data", []):
            d = item.get("data", {})
            char = d.get("characters") or "—"
            obj_type = item.get("object", "?")
            meanings = ", ".join(m["meaning"] for m in d.get("meanings", []))
            results.append(f"{char} [{obj_type}] {meanings}")
        return "\n".join(results[:50]) if results else f"No subjects at level {level}"

    if query:
        # WaniKani API doesn't have a direct character search filter.
        # Fetch subjects for levels 1-60 and filter client-side by character/slug.
        # Limit to first 10 pages (~5000 subjects) to keep it fast.
        data = api_get("/subjects?filter[levels]=1,2,3,4,5,6,7,8,9,10", 10)
        if data.get("total_count", 0) == 0:
            data = api_get("/subjects", 10)

        q = query.lower()
        results = []
        seen = set()
        for item in data.get("data", []):
            d = item.get("data", {})
            char = d.get("characters", "") or ""
            # Match by exact character
            if char == query:
                key = f"{char}-{item.get('object', '?')}"
                if key not in seen:
                    seen.add(key)
                    obj_type = item.get("object", "?")
                    meanings = ", ".join(m["meaning"] for m in d.get("meanings", []))
                    readings = d.get("readings", [])
                    reading_str = ", ".join(
                        f"{r['reading']}{'★' if r.get('primary') else ''}"
                        for r in readings
                    )
                    level_num = d.get("level", "?")
                    results.append(f"{char} [{obj_type}] {meanings}\n  Readings: {reading_str}\n  Level {level_num}")

        if not results:
            # Try matching by slug (meaning)
            for item in data.get("data", []):
                d = item.get("data", {})
                char = d.get("characters", "") or ""
                meanings = [m["meaning"].lower() for m in d.get("meanings", [])]
                if q in meanings or q in char.lower():
                    key = f"{char}-{item.get('object', '?')}"
                    if key not in seen:
                        seen.add(key)
                        obj_type = item.get("object", "?")
                        meanings_str = ", ".join(m["meaning"] for m in d.get("meanings", []))
                        readings = d.get("readings", [])
                        reading_str = ", ".join(
                            f"{r['reading']}{'★' if r.get('primary') else ''}"
                            for r in readings
                        )
                        level_num = d.get("level", "?")
                        results.append(f"{char} [{obj_type}] {meanings_str}\n  Readings: {reading_str}\n  Level {level_num}")

        return "\n\n".join(results[:20]) if results else f"No subjects found for: {query}"

    return "Usage: subjects <character|slug> or subjects --level <N>"


SRS_LABELS = {
    "apprentice": "1,2,3,4",
    "guru": "5,6,7",
    "master": "8,9",
    "enlightened": "9",
    "burned": "10",
    "locked": "0",
}


def cmd_assignments(stage=None):
    if stage and stage in SRS_LABELS:
        data = api_get(f"/assignments?filter[srs_stages]={SRS_LABELS[stage]}", 3)
        results = []
        for item in data.get("data", [])[:20]:
            d = item.get("data", {})
            sid = d.get("subject_id", "?")
            srs = d.get("srs_stage", "?")
            unlocked = fmt_date(d.get("unlocked_at"))
            results.append(f"Subject {sid} — Stage {srs} | Unlocked: {unlocked}")
        return "\n".join(results) if results else f"No items in {stage} stage"
    else:
        data = api_get("/assignments", 10)
        stages = {}
        for item in data.get("data", []):
            srs = item.get("data", {}).get("srs_stage", -1)
            stages[srs] = stages.get(srs, 0) + 1
        return "\n".join(f"Stage {k}: {v} items" for k, v in sorted(stages.items()))


def cmd_reviews(limit=10):
    data = api_get("/reviews", 1)
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
    return "\n".join(results) if results else "No reviews found."


def cmd_review_stats():
    data = api_get("/review_statistics", 3)
    items = data.get("data", [])
    if not items:
        return "No review statistics yet — need more reviews!"

    scores = [
        i["data"]["percentage_correct"]
        for i in items
        if i.get("data", {}).get("percentage_correct") is not None
    ]
    if not scores:
        return "No review statistics yet."

    avg = sum(scores) / len(scores)
    lines = [f"📈 Review Statistics", f"Items with stats: {len(scores)}", f"Average accuracy: {avg:.0f}%"]

    struggling = [
        i for i in items
        if i.get("data", {}).get("percentage_correct") is not None
        and i["data"]["percentage_correct"] < 80
    ]
    for s in sorted(struggling, key=lambda x: x["data"]["percentage_correct"])[:10]:
        d = s["data"]
        sid = s.get("data", {}).get("subject_id") or s.get("id", "?")
        total_mistakes = d.get("meaning_incorrect", 0) + d.get("reading_incorrect", 0)
        lines.append(f"⚠️ Subject {sid}: {d['percentage_correct']}% accuracy ({total_mistakes} mistakes)")

    return "\n".join(lines)


def cmd_levels():
    data = api_get("/level_progressions")
    results = []
    for item in data.get("data", []):
        d = item.get("data", {})
        lvl = d.get("level", "?")
        unlocked = fmt_date(d.get("unlocked_at"))
        passed = fmt_date(d.get("passed_at"))
        completed = fmt_date(d.get("completed_at"))
        results.append(f"Level {lvl}: {unlocked} → {passed} → {completed}")
    return "\n".join(results) if results else "No level data yet."


def cmd_leeches():
    data = api_get("/review_statistics", 5)
    items = data.get("data", [])
    leeches = [
        i for i in items
        if i.get("data", {}).get("percentage_correct") is not None
        and i["data"]["percentage_correct"] < 70
    ]
    if not leeches:
        return "No leeches found — doing great! 🎉"

    leeches.sort(key=lambda x: x["data"]["percentage_correct"])
    lines = []
    for s in leeches[:10]:
        d = s["data"]
        sid = d.get("subject_id") or s.get("id", "?")
        pct = d["percentage_correct"]
        mistakes = d.get("meaning_incorrect", 0) + d.get("reading_incorrect", 0)
        lines.append(f"🐛 Subject {sid}: {pct}% — {mistakes} mistakes total")
    return "\n".join(lines)


def cmd_help():
    return """WaniKani API CLI

Commands:
  user|me              Profile info (level, username, plan)
  summary|forecast     Today's review forecast
  subjects <char|slug> Look up a kanji/vocab/radical
  subjects --level <N> List subjects at a level
  assignments|srs      SRS stage distribution
  assignments <stage>  Items in a specific SRS stage
  reviews [limit]      Recent review history
  review-stats|acc     Accuracy statistics
  levels|progression   Level progress timeline
  leeches|struggles    Subjects below 70% accuracy"""


def main():
    args = sys.argv[1:]
    if not args:
        print(cmd_help())
        return

    cmd = args[0]

    commands = {
        "user": cmd_user,
        "me": cmd_user,
        "summary": cmd_summary,
        "forecast": cmd_summary,
        "subjects": lambda: cmd_subjects(
            query=" ".join(a for a in args[1:] if not a.startswith("--")),
            level=args[args.index("--level") + 1] if "--level" in args else None,
        ),
        "kanji": lambda: cmd_subjects(query=args[1] if len(args) > 1 else None),
        "vocab": lambda: cmd_subjects(query=args[1] if len(args) > 1 else None),
        "assignments": lambda: cmd_assignments(args[1] if len(args) > 1 else None),
        "srs": lambda: cmd_assignments(args[1] if len(args) > 1 else None),
        "reviews": lambda: cmd_reviews(int(args[1]) if len(args) > 1 and args[1].isdigit() else 10),
        "history": lambda: cmd_reviews(int(args[1]) if len(args) > 1 and args[1].isdigit() else 10),
        "review-stats": cmd_review_stats,
        "accuracy": cmd_review_stats,
        "acc": cmd_review_stats,
        "levels": cmd_levels,
        "progression": cmd_levels,
        "leeches": cmd_leeches,
        "struggles": cmd_leeches,
    }

    handler = commands.get(cmd)
    if handler:
        result = handler()
        if result is not None:
            print(result)
    else:
        print(cmd_help())
        sys.exit(1)


if __name__ == "__main__":
    main()
