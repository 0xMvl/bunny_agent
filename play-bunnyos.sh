#!/bin/bash
export BUNNYOS_API_KEY="bos_432b85674b64732783a51bc8efd9a6527f730d68f7b0208ce619519836813d49"
API="https://world.bunnyos.ai/v1"
AUTH="Authorization: Bearer $BUNNYOS_API_KEY"
LOG="/root/bunny/play.log"

log() { echo "[$(TZ='Asia/Jakarta' date '+%H:%M:%S')] $1" >> "$LOG"; }

log "=== AUTO PLAY START ==="

# 1. Read announcements (check skillVersion)
SKILL=$(curl -s "$API/announcements" -H "$AUTH" | jq -r '.skillVersion')
log "Skill version: $SKILL"

# 2. Claim completed event rewards
EVENTS=$(curl -s "$API/events" -H "$AUTH")
echo "$EVENTS" | jq -r '.events[] | select(.completedAt != null and .claimedAt == null) | .id' | while read eid; do
  if [ -n "$eid" ]; then
    RESULT=$(curl -s -X POST "$API/events/$eid/claim" -H "$AUTH")
    REWARD=$(echo "$RESULT" | jq -r '.reward.carrots // 0')
    log "Claimed event $eid → +${REWARD} carrots"
  fi
done

# 3. Check in-progress missions (this resolves completed ones)
IN_PROGRESS=$(curl -s "$API/missions?status=in_progress" -H "$AUTH")
ACTIVE_COUNT=$(echo "$IN_PROGRESS" | jq '.missions | length')
log "Active missions: $ACTIVE_COUNT"

# 4. Sell hauls from succeeded missions
SUCCEEDED=$(curl -s "$API/missions?status=succeeded&limit=10" -H "$AUTH")
echo "$SUCCEEDED" | jq -c '.missions[] | select(.haul != null and (.haul | length) > 0)' | while read mission; do
  MNAME=$(echo "$mission" | jq -r '.name')
  log "Selling haul from: $MNAME"
  echo "$mission" | jq -c '.haul[]' | while read item; do
    KEY=$(echo "$item" | jq -r '.key')
    QTY=$(echo "$item" | jq -r '.quantity')
    SELL_RESULT=$(curl -s -X POST "$API/items/$KEY/sell" -H "$AUTH" -H "Content-Type: application/json" -d "{\"quantity\":$QTY}")
    CARROTS=$(echo "$SELL_RESULT" | jq -r '.carrots // "error"')
    log "  Sold $QTY × $KEY → balance: $CARROTS"
  done
done

# 5. Get current state
ACCOUNT=$(curl -s "$API/accounts/me" -H "$AUTH")
CARROTS=$(echo "$ACCOUNT" | jq -r '.carrots')
BUNNY=$(curl -s "$API/bunny" -H "$AUTH")
SLOTS=$(echo "$BUNNY" | jq -r '.missionSlots')
INVENTORY=$(curl -s "$API/inventory" -H "$AUTH")
EQUIPPED_POWER=$(echo "$INVENTORY" | jq '[.equipment[] | select(.equippedBunnyId != null) | .power] | add // 0')
TOTAL_POWER=$((100 + EQUIPPED_POWER))
log "Carrots: $CARROTS | Power: $TOTAL_POWER | Slots: $SLOTS"

# 6. Accept new missions if slots available
ACTIVE_COUNT=$(curl -s "$API/missions?status=in_progress" -H "$AUTH" | jq '.missions | length')
AVAILABLE_SLOTS=$((SLOTS - ACTIVE_COUNT))

if [ "$AVAILABLE_SLOTS" -gt 0 ]; then
  log "Available slots: $AVAILABLE_SLOTS — looking for missions..."

  # Get zone board
  ZONE=$(curl -s "$API/zones/sunny_meadow" -H "$AUTH")

  # Sort missions by value (lower mob power = higher chance)
  echo "$ZONE" | jq -c '.missions[] | select(.pinned == true or .entryCost <= '"$CARROTS"')' | sort -t, -k4 -n | while read mission; do
    if [ "$AVAILABLE_SLOTS" -le 0 ]; then break; fi

    MID=$(echo "$mission" | jq -r '.id')
    MNAME=$(echo "$mission" | jq -r '.name')
    COST=$(echo "$mission" | jq -r '.entryCost')
    MOB=$(echo "$mission" | jq -r '.mobPower')

    # Check if we can afford it
    if (( $(echo "$COST <= $CARROTS" | bc -l) )); then
      ACCEPT=$(curl -s -X POST "$API/missions" -H "$AUTH" -H "Content-Type: application/json" -d '{"boardMissionId":"'"$MID"'"}')
      STATUS=$(echo "$ACCEPT" | jq -r '.status // "error"')
      CHANCE=$(echo "$ACCEPT" | jq -r '.successChance // 0')
      if [ "$STATUS" = "in_progress" ]; then
        log "Accepted: $MNAME (mob:$MOB, cost:$COST, chance:$(echo "$CHANCE * 100" | bc)%)"
        CARROTS=$(echo "$CARROTS - $COST" | bc)
        AVAILABLE_SLOTS=$((AVAILABLE_SLOTS - 1))
      else
        ERROR=$(echo "$ACCEPT" | jq -r '.message // "unknown"')
        log "Failed to accept $MNAME: $ERROR"
      fi
    fi
  done
else
  log "All $SLOTS mission slots busy"
fi

# 7. Repair equipped gear if durability low
echo "$INVENTORY" | jq -c '.equipment[] | select(.equippedBunnyId != null and .durability < .maxDurability * 0.5)' | while read item; do
  IID=$(echo "$item" | jq -r '.id')
  INAME=$(echo "$item" | jq -r '.name')
  DUR=$(echo "$item" | jq -r '.durability')
  MAX=$(echo "$item" | jq -r '.maxDurability')
  REPAIR=$(curl -s -X POST "$API/inventory/$IID/repair" -H "$AUTH")
  COST=$(echo "$REPAIR" | jq -r '.fee // 0')
  log "Repaired $INAME ($DUR/$MAX) → cost: $COST"
done

# 8. Final balance
FINAL=$(curl -s "$API/accounts/me" -H "$AUTH" | jq -r '.carrots')
log "Final balance: $FINAL carrots"
log "=== AUTO PLAY END ==="
echo "" >> "$LOG"
