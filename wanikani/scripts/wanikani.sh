#!/bin/bash
# wanikani.sh — WaniKani API CLI wrapper
# Usage: ./scripts/wanikani.sh <command> [args]

WANIKANI_ACCESS_TOKEN="${WANIKANI_ACCESS_TOKEN:-$(grep 'WANIKANI_ACCESS_TOKEN' /home/ada/.openclaw/.env 2>/dev/null | cut -d= -f2 | tr -d '\"')}"
BASE="https://api.wanikani.com/v2"

if [ -z "$WANIKANI_ACCESS_TOKEN" ]; then
  echo '{"error":"WANIKANI_ACCESS_TOKEN not set"}' >&2
  exit 1
fi

AUTH="Authorization: Bearer $WANIKANI_ACCESS_TOKEN"
UA="User-Agent: wanikani-skill/1.0"

wanikani_get() {
  local url="$1"
  local max_pages="${2:-1}"
  local page=0
  local data=""

  while [ "$page" -lt "$max_pages" ] && [ -n "$url" ] && [ "$url" != "null" ]; do
    local resp
    resp=$(curl -s -H "$AUTH" -H "$UA" "$url")
    if [ "$page" -eq 0 ]; then
      data="$resp"
    else
      data=$(echo "$data" "$resp" | jq -s '.[0].data + .[1].data | {data: ., pages: .[1].pages}')
    fi
    url=$(echo "$resp" | jq -r '.pages.next_url // empty')
    page=$((page + 1))
  done
  echo "$data"
}

# ── Command: user — profile info ──
cmd_user() {
  local resp
  resp=$(curl -s -H "$AUTH" -H "$UA" "$BASE/user")
  local lvl=$(echo "$resp" | jq -r '.data.level')
  local user=$(echo "$resp" | jq -r '.data.username')
  local started=$(echo "$resp" | jq -r '.data.started_at' | cut -dT -f1)
  local sub=$(echo "$resp" | jq -r '.data.subscription.type // "free"')
  local max_lvl=$(echo "$resp" | jq -r '.data.subscription.max_level_granted // "3"')

  echo "📊 WaniKani Profile — $user"
  echo "Level: $lvl"
  echo "Member since: $started"
  echo "Plan: $sub (max level $max_lvl)"
}

# ── Command: summary — today's forecast ──
cmd_summary() {
  local resp
  resp=$(curl -s -H "$AUTH" -H "$UA" "$BASE/summary")
  local reviews=$(echo "$resp" | jq -r '.data.reviews[0] // empty')
  
  if [ -n "$reviews" ]; then
    local available=$(echo "$reviews" | jq -r '.available_at // "now"')
    local count=$(echo "$reviews" | jq -r '.subject_ids | length')
    echo "📝 Review Forecast"
    echo "Next review batch: $count items"
    echo "Available at: $(date -d "$available" '+%b %d, %I:%M %p' 2>/dev/null || echo "$available")"
    
    local lessons=$(echo "$resp" | jq -r '.data.lessons[0].subject_ids // [] | length')
    echo "Lessons available: $lessons"
  else
    echo "📝 Review Forecast"
    echo "No upcoming reviews scheduled"
  fi
}

# ── Command: subjects — look up subjects ──
cmd_subjects() {
  local query=""
  local level=""

  # Parse args
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --level) shift; level="$1" ;;
      *) query="$1" ;;
    esac
    shift
  done

  if [ -n "$query" ]; then
    # Look up a specific character
    # URL-encode if needed
    local encoded_query=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$query'))" 2>/dev/null || echo "$query")
    local resp
    resp=$(curl -s -H "$AUTH" -H "$UA" "${BASE}/subjects?filter=characters&slugs=${encoded_query}")
    local total=$(echo "$resp" | jq -r '.total_count // 0')
    if [ "$total" -eq 0 ]; then
      # Try as slug
      resp=$(curl -s -H "$AUTH" -H "$UA" "${BASE}/subjects?filter=slugs&slugs=${encoded_query}")
      total=$(echo "$resp" | jq -r '.total_count // 0')
    fi

    if [ "$total" -eq 0 ]; then
      echo "No subjects found for: $query"
      return
    fi

    echo "$resp" | jq -r '.data[] | 
    "\(.data.characters // "—") [\(.object)] \(.data.meanings | map(.meaning) | join(", "))\n  Readings: \(.data.readings // [] | map(.reading + if .primary then "★" else "" end) | join(", "))\n  Level \(.data.level)\n"'
  elif [ -n "$level" ]; then
    local resp
    resp=$(wanikani_get "${BASE}/subjects?filter/levels=${level}" 5)
    echo "$resp" | jq -r '.data[] | 
    "\(.data.characters // "—") [\(.object)] \(.data.meanings | map(.meaning) | join(", "))"'
  else
    echo "Usage: scripts/wanikani.sh subjects <character|slug>"
    echo "       scripts/wanikani.sh subjects --level <N>"
  fi
}

# ── Command: assignments — SRS progress ──
cmd_assignments() {
  local srs="${1:-}"

  local url="$BASE/assignments"
  if [ -n "$srs" ]; then
    case "$srs" in
      apprentice) url="$url?filter[srs_stages]=1,2,3,4" ;;
      guru)       url="$url?filter[srs_stages]=5,6,7" ;;
      master)     url="$url?filter[srs_stages]=8,9" ;;
      enlightened) url="$url?filter[srs_stages]=9" ;;
      burned)     url="$url?filter[srs_stages]=10" ;;
      locked)     url="$url?filter[srs_stages]=0" ;;
      *)
        echo "SRS stages: apprentice (1-4), guru (5-7), master (8-9), enlightened (9), burned (10), locked (0)"
        return
        ;;
    esac
  else
    # Summary: count by SRS stage
    local resp
    resp=$(wanikani_get "$BASE/assignments?page_after_id=0" 10)
    echo "$resp" | jq -r '.data | group_by(.data.srs_stage) | 
      map("Stage \(.[0].data.srs_stage): \(length) items") | .[]'
    return
  fi

  local resp
  resp=$(wanikani_get "$url" 3)
  echo "$resp" | jq -r '.data[:20][] | 
    "Subject \(.data.subject_id) — Stage \(.data.srs_stage) | Unlocked: \(.data.unlocked_at // "—" | .[:10])"'
}

# ── Command: reviews — recent review history ──
cmd_reviews() {
  local limit="${1:-10}"

  local resp
  resp=$(curl -s -H "$AUTH" -H "$UA" "${BASE}/reviews?page_after_id=0")
  echo "$resp" | jq -r '.data[:'"$limit"'] | 
    map("Review #\(.id): Subject \(.data.subject_id) — \(if .data.starting_srs_stage < .data.ending_srs_stage then "✅" else "❌" end) SRS \(.data.starting_srs_stage)→\(.data.ending_srs_stage) (\(.data.created_at[:10]))") | .[]'
}

# ── Command: review_stats — review statistics ──
cmd_review_stats() {
  local resp
  resp=$(curl -s -H "$AUTH" -H "$UA" "${BASE}/review_statistics?page_after_id=0")
  local total=$(echo "$resp" | jq -r '.total_count // 0')
  
  if [ "$total" -eq 0 ]; then
    echo "No review statistics yet — need more reviews!"
    return
  fi
  
  echo "$resp" | jq -r '
    [.data[] | select(.data.percentage_correct != null) | .data.percentage_correct] as $scores |
    ($scores | add / ($scores | length)) as $avg |
    "📈 Review Statistics\nItems with stats: \($scores | length)\nAverage accuracy: \($avg | floor)%"'
  
  # Subjects needing attention (below 80%)
  echo "$resp" | jq -r '
    .data[] | select(.data.percentage_correct != null and .data.percentage_correct < 80) |
    "⚠️ Subject \(.data.subject_id): \(.data.percentage_correct)% accuracy (\(.data.meaning_incorrect + .data.reading_incorrect) mistakes)"' | head -10
}

# ── Command: levels — level progression ──
cmd_levels() {
  local resp
  resp=$(curl -s -H "$AUTH" -H "$UA" "${BASE}/level_progressions")
  echo "$resp" | jq -r '.data[] |
    "Level \(.data.level): \(.data.unlocked_at[:10] // "—") → \(.data.passed_at[:10] // "not passed") → \(.data.completed_at[:10] // "not completed")"'
}

# ── Command: leeches — worst subjects ──
cmd_leeches() {
  local resp
  resp=$(curl -s -H "$AUTH" -H "$UA" "${BASE}/review_statistics?page_after_id=0")

  echo "$resp" | jq -r '
    .data[] | select(.data.percentage_correct != null and .data.percentage_correct < 70) |
    "🐛 Subject \(.data.subject_id): \(.data.percentage_correct)% — \(.data.meaning_incorrect + .data.reading_incorrect) mistakes total"' | sort -t: -k2 -n | head -10

  if [ -z "$(echo "$resp" | jq -r '.data[] | select(.data.percentage_correct != null and .data.percentage_correct < 70) | .data.subject_id' 2>/dev/null)" ]; then
    echo "No leeches found — doing great! 🎉"
  fi
}

# ── Dispatch ──
case "${1:-}" in
  user|profile|me)       cmd_user ;;
  summary|forecast)      cmd_summary ;;
  subjects|kanji|vocab)  shift; cmd_subjects "$@" ;;
  assignments|srs)       shift; cmd_assignments "$@" ;;
  reviews|history)       shift; cmd_reviews "$@" ;;
  review-stats|accuracy) cmd_review_stats ;;
  levels|progression)    cmd_levels ;;
  leeches|struggles)     cmd_leeches ;;
  *)
    echo "WaniKani API CLI"
    echo ""
    echo "Commands:"
    echo "  user|me              — Profile info (level, username, plan)"
    echo "  summary|forecast     — Today's review forecast"
    echo "  subjects <char|slug> — Look up a kanji/vocab/radical"
    echo "  subjects --level <N> — List subjects at a level"
    echo "  assignments|srs      — SRS stage distribution"
    echo "  assignments <stage>  — Items in a specific SRS stage"
    echo "  reviews [limit]      — Recent review history"
    echo "  review-stats|acc     — Accuracy statistics"
    echo "  levels|progression   — Level progress timeline"
    echo "  leeches|struggles    — Subjects below 70% accuracy"
    exit 1
    ;;
esac
