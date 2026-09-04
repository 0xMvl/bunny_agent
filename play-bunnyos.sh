#!/bin/bash
export BUNNYOS_API_KEY="bos_432b85674b64732783a51bc8efd9a6527f730d68f7b0208ce619519836813d49"
API="https://world.bunnyos.ai/v1"
AUTH="Authorization: Bearer $BUNNYOS_API_KEY"
LOG="/root/bunny/play.log"

log() { echo "[$(TZ='Asia/Jakarta' date '+%H:%M:%S')] $1" >> "$LOG"; }

# Helper: API call
api() {
  local method="$1" endpoint="$2" data="$3"
  if [ -n "$data" ]; then
    curl -s -X "$method" "$API$endpoint" -H "$AUTH" -H "Content-Type: application/json" -d "$data"
  else
    curl -s -X "$method" "$API$endpoint" -H "$AUTH"
  fi
}

log "=== AUTO PLAY START ==="

# 1. Read announcements (check skillVersion)
SKILL=$(api GET /announcements | jq -r '.skillVersion')
log "Skill version: $SKILL"

# 2. Claim completed event rewards
EVENTS=$(api GET /events)
echo "$EVENTS" | jq -r '.events[] | select(.completedAt != null and .claimedAt == null) | .id' | while read eid; do
  if [ -n "$eid" ]; then
    RESULT=$(api POST "/events/$eid/claim")
    REWARD=$(echo "$RESULT" | jq -r '.reward.carrots // 0')
    ENAME=$(echo "$EVENTS" | jq -r ".events[] | select(.id == \"$eid\") | .name")
    log "Claimed event: $ENAME → +${REWARD} carrots"
  fi
done

# 3. Check in-progress missions (this resolves completed ones)
IN_PROGRESS=$(api GET "/missions?status=in_progress")
ACTIVE_COUNT=$(echo "$IN_PROGRESS" | jq '.missions | length')
log "Active missions: $ACTIVE_COUNT"

# 4. Equip all available gear (only when no active missions)
ACTIVE_COUNT=$(api GET "/missions?status=in_progress" | jq '.missions | length')
if [ "$ACTIVE_COUNT" -eq 0 ]; then
  log "Equipping gear..."
  INVENTORY=$(api GET /inventory)
  
  # Build equipment list: all items with durability > 0
  EQUIP_LIST=$(echo "$INVENTORY" | jq -c '[.equipment[] | select(.durability > 0) | .id]')
  EQUIP_COUNT=$(echo "$EQUIP_LIST" | jq 'length')
  
  log "  Found $EQUIP_COUNT items to equip"
  
  # Log what we're equipping
  echo "$INVENTORY" | jq -r '.equipment[] | select(.durability > 0) | "  Equipping: \(.name) (slot:\(.slot), power:\(.power))"' >> "$LOG"
  
  # Update bunny equipment
  if [ "$EQUIP_COUNT" -gt 0 ]; then
    RESULT=$(api PATCH "/bunny" "{\"equipment\":$EQUIP_LIST}")
    STATUS=$(echo "$RESULT" | jq -r '.error // empty')
    if [ -n "$STATUS" ]; then
      log "  Equip failed: $STATUS"
    else
      log "  Gear equipped successfully"
    fi
  fi
else
  log "Skipping equip — $ACTIVE_COUNT missions in flight (loadout locked)"
fi

# 5. Complete onboarding events (only when no active missions)
ACTIVE_COUNT=$(api GET "/missions?status=in_progress" | jq '.missions | length')
if [ "$ACTIVE_COUNT" -eq 0 ]; then
  log "Checking onboarding events..."
  EVENTS=$(api GET /events)

# Buy12 Timber (cost: 24 carrots, reward: 75 carrots)
TIMBER_EVENT=$(echo "$EVENTS" | jq -r '.events[] | select(.templateKey == "onboarding_buy_timber" and .completedAt == null)')
if [ -n "$TIMBER_EVENT" ]; then
  PROGRESS=$(echo "$TIMBER_EVENT" | jq -r '.progress')
  if [ "$PROGRESS" -lt 12 ]; then
    NEEDED=$((12 - PROGRESS))
    log "  Buying $NEEDED Timber for onboarding..."
    for i in $(seq 1 $NEEDED); do
      RESULT=$(api POST "/items/timber/buy" '{"quantity":1}')
    done
    # Claim reward
    EVENT_ID=$(echo "$EVENTS" | jq -r '.events[] | select(.templateKey == "onboarding_buy_timber") | .id')
    if [ -n "$EVENT_ID" ]; then
      api POST "/events/$EVENT_ID/claim" > /dev/null
      log "  Claimed: Buy Timber → +75 carrots"
    fi
  fi
fi

# Craft2 Planks (cost: 20 carrots, reward: 100 carrots)
PLANK_EVENT=$(echo "$EVENTS" | jq -r '.events[] | select(.templateKey == "onboarding_craft_planks" and .completedAt == null)')
if [ -n "$PLANK_EVENT" ]; then
  PROGRESS=$(echo "$PLANK_EVENT" | jq -r '.progress')
  if [ "$PROGRESS" -lt 2 ]; then
    NEEDED=$((2 - PROGRESS))
    log "  Crafting $NEEDED Planks for onboarding..."
    for i in $(seq 1 $NEEDED); do
      RESULT=$(api POST "/items/plank/craft")
    done
    # Claim reward
    EVENT_ID=$(echo "$EVENTS" | jq -r '.events[] | select(.templateKey == "onboarding_craft_planks") | .id')
    if [ -n "$EVENT_ID" ]; then
      api POST "/events/$EVENT_ID/claim" > /dev/null
      log "  Claimed: Craft Planks → +100 carrots"
    fi
  fi
fi

# Craft2 Ropes (cost: 20 carrots, reward: 75 carrots)
ROPE_EVENT=$(echo "$EVENTS" | jq -r '.events[] | select(.templateKey == "onboarding_craft_ropes" and .completedAt == null)')
if [ -n "$ROPE_EVENT" ]; then
  PROGRESS=$(echo "$ROPE_EVENT" | jq -r '.progress')
  if [ "$PROGRESS" -lt 2 ]; then
    NEEDED=$((2 - PROGRESS))
    log "  Crafting $NEEDED Ropes for onboarding..."
    for i in $(seq 1 $NEEDED); do
      RESULT=$(api POST "/items/rope/craft")
    done
    # Claim reward
    EVENT_ID=$(echo "$EVENTS" | jq -r '.events[] | select(.templateKey == "onboarding_craft_ropes") | .id')
    if [ -n "$EVENT_ID" ]; then
      api POST "/events/$EVENT_ID/claim" > /dev/null
      log "  Claimed: Craft Ropes → +75 carrots"
    fi
  fi
fi

# Craft Slingshot (cost: 40 carrots, reward: 375 carrots)
SLINGSHOT_EVENT=$(echo "$EVENTS" | jq -r '.events[] | select(.templateKey == "onboarding_craft_slingshot" and .completedAt == null)')
if [ -n "$SLINGSHOT_EVENT" ]; then
  log "  Crafting Slingshot for onboarding..."
  RESULT=$(api POST "/items/slingshot/craft")
  STATUS=$(echo "$RESULT" | jq -r '.error // empty')
  if [ -z "$STATUS" ]; then
    # Claim reward
    EVENT_ID=$(echo "$EVENTS" | jq -r '.events[] | select(.templateKey == "onboarding_craft_slingshot") | .id')
    if [ -n "$EVENT_ID" ]; then
      api POST "/events/$EVENT_ID/claim" > /dev/null
      log "  Claimed: Craft Slingshot → +375 carrots"
    fi
  else
    log "  Craft Slingshot failed: $STATUS"
  fi
fi

# Equip Slingshot (reward: 75 carrots)
EQUIP_SLINGSHOT_EVENT=$(echo "$EVENTS" | jq -r '.events[] | select(.templateKey == "onboarding_equip_slingshot" and .completedAt == null)')
if [ -n "$EQUIP_SLINGSHOT_EVENT" ]; then
  # Check if we have slingshot
  SLINGSHOT=$(api GET /inventory | jq -r '.equipment[] | select(.name == "Slingshot") | .id')
  if [ -n "$SLINGSHOT" ]; then
    # Equip it
    api PATCH "/bunny" "{\"equipment\":[\"$SLINGSHOT\"]}" > /dev/null
    # Claim reward
    EVENT_ID=$(echo "$EVENTS" | jq -r '.events[] | select(.templateKey == "onboarding_equip_slingshot") | .id')
    if [ -n "$EVENT_ID" ]; then
      api POST "/events/$EVENT_ID/claim" > /dev/null
      log "  Claimed: Equip Slingshot → +75 carrots"
    fi
  fi
fi

# Repair any item (reward: 200 carrots)
REPAIR_EVENT=$(echo "$EVENTS" | jq -r '.events[] | select(.templateKey == "onboarding_repair_item" and .completedAt == null)')
if [ -n "$REPAIR_EVENT" ]; then
  # Find any item with durability < maxDurability
  REPAIRABLE=$(api GET /inventory | jq -r '.equipment[] | select(.durability < .maxDurability) | .id' | head -1)
  if [ -n "$REPAIRABLE" ]; then
    RESULT=$(api POST "/inventory/$REPAIRABLE/repair")
    STATUS=$(echo "$RESULT" | jq -r '.error // empty')
    if [ -z "$STATUS" ]; then
      EVENT_ID=$(echo "$EVENTS" | jq -r '.events[] | select(.templateKey == "onboarding_repair_item") | .id')
      if [ -n "$EVENT_ID" ]; then
        api POST "/events/$EVENT_ID/claim" > /dev/null
        log "  Claimed: Repair Item → +200 carrots"
      fi
    fi
  fi
fi

else
  log "Skipping onboarding — $ACTIVE_COUNT missions in flight (loadout locked)"
fi

# 6. Sell materials (keep some for crafting)
log "Selling materials..."
INVENTORY=$(api GET /inventory)
echo "$INVENTORY" | jq -c '.materials[] | select(.quantity > 0)' | while read item; do
  KEY=$(echo "$item" | jq -r '.key')
  QTY=$(echo "$item" | jq -r '.quantity')
  INAME=$(echo "$item" | jq -r '.name // .key')
  
  # Keep materials needed for crafting: timber, fiber, straw, dust_tuft, patch_scraps
  case "$KEY" in
    timber|fiber|straw|dust_tuft|patch_scraps|fang|chitin|trinket)
      # Keep 5 of each for crafting, sell excess
      if [ "$QTY" -gt 5 ]; then
        SELL_QTY=$((QTY - 5))
        HTTP_CODE=$(curl -s -o /tmp/sell_result.json -w "%{http_code}" -X POST "$API/items/$KEY/sell" -H "$AUTH" -H "Content-Type: application/json" -d "{\"quantity\":$SELL_QTY}")
        if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
          CARROTS=$(cat /tmp/sell_result.json | jq -r '.carrots // .balance // "ok"')
          log "  Sold $SELL_QTY × $INAME (kept 5) → balance: $CARROTS"
        fi
      fi
      ;;
    *)
      # Sell all of other materials
      HTTP_CODE=$(curl -s -o /tmp/sell_result.json -w "%{http_code}" -X POST "$API/items/$KEY/sell" -H "$AUTH" -H "Content-Type: application/json" -d "{\"quantity\":$QTY}")
      if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
        CARROTS=$(cat /tmp/sell_result.json | jq -r '.carrots // .balance // "ok"')
        log "  Sold $QTY × $INAME → balance: $CARROTS"
      else
        ERROR_MSG=$(cat /tmp/sell_result.json | jq -r '.message // "unknown error"')
        log "  Sell failed $QTY × $INAME → HTTP $HTTP_CODE: $ERROR_MSG"
      fi
      ;;
  esac
done

# 7. Get current state
ACCOUNT=$(api GET /accounts/me)
CARROTS=$(echo "$ACCOUNT" | jq -r '.carrots')
BUNNY=$(api GET /bunny)
SLOTS=$(echo "$BUNNY" | jq -r '.missionSlots')
INVENTORY=$(api GET /inventory)
EQUIPPED_POWER=$(echo "$INVENTORY" | jq '[.equipment[] | select(.equippedBunnyId != null) | .power] | add // 0')
TOTAL_POWER=$((100 + EQUIPPED_POWER))
log "Carrots: $CARROTS | Power: $TOTAL_POWER | Slots: $SLOTS"

# 8. Accept new missions if slots available
ACTIVE_COUNT=$(api GET "/missions?status=in_progress" | jq '.missions | length')
AVAILABLE_SLOTS=$((SLOTS - ACTIVE_COUNT))

if [ "$AVAILABLE_SLOTS" -gt 0 ]; then
  log "Available slots: $AVAILABLE_SLOTS — looking for missions..."

  # Get zone board, sort by priority:
  # 1. Free missions (cost=0) first
  # 2. Then by success chance descending (>70% preferred)
  # 3. Then by cost ascending
  MISSIONS=$(api GET /zones/sunny_meadow | jq -c '[.missions[] | select(.pinned == true or .entryCost <= '"$CARROTS"')] | sort_by(.entryCost) | sort_by(-.successChance)[]')

  while read mission; do
    if [ "$AVAILABLE_SLOTS" -le 0 ]; then break; fi

    MID=$(echo "$mission" | jq -r '.id')
    MNAME=$(echo "$mission" | jq -r '.name')
    COST=$(echo "$mission" | jq -r '.entryCost')
    MOB=$(echo "$mission" | jq -r '.mobPower')

    # Skip expensive missions (>15 carrots) unless free
    if (( $(echo "$COST > 15" | bc -l) )); then
      continue
    fi

    # Check if we can afford it
    if (( $(echo "$COST <= $CARROTS" | bc -l) )); then
      ACCEPT=$(api POST "/missions" '{"boardMissionId":"'"$MID"'"}')
      STATUS=$(echo "$ACCEPT" | jq -r '.status // "error"')
      CHANCE=$(echo "$ACCEPT" | jq -r '.successChance // 0')
      if [ "$STATUS" = "in_progress" ]; then
        CHANCE_PCT=$(echo "$CHANCE * 100" | bc 2>/dev/null || echo "?")
        log "Accepted: $MNAME (mob:$MOB, cost:$COST, chance:${CHANCE_PCT}%)"
        CARROTS=$(echo "$CARROTS - $COST" | bc)
        AVAILABLE_SLOTS=$((AVAILABLE_SLOTS - 1))
      else
        ERROR=$(echo "$ACCEPT" | jq -r '.message // "unknown"')
        log "Failed to accept $MNAME: $ERROR"
      fi
    fi
  done <<< "$MISSIONS"
else
  log "All $SLOTS mission slots busy"
fi

# 9. Repair equipped gear if durability low (only when no active missions)
ACTIVE_COUNT=$(api GET "/missions?status=in_progress" | jq '.missions | length')
if [ "$ACTIVE_COUNT" -eq 0 ]; then
  log "No active missions — repairing gear..."
  REPAIR_ITEMS=$(api GET /inventory | jq -c '.equipment[] | select(.equippedBunnyId != null and .durability < .maxDurability * 0.5)')
  while read item; do
    IID=$(echo "$item" | jq -r '.id')
    INAME=$(echo "$item" | jq -r '.name')
    DUR=$(echo "$item" | jq -r '.durability')
    MAX=$(echo "$item" | jq -r '.maxDurability')
    REPAIR=$(api POST "/inventory/$IID/repair")
    COST=$(echo "$REPAIR" | jq -r '.fee // 0')
    STATUS=$(echo "$REPAIR" | jq -r '.error // empty')
    if [ -n "$STATUS" ]; then
      log "Repair failed $INAME ($DUR/$MAX): $STATUS"
    else
      log "Repaired $INAME ($DUR/$MAX) → cost: $COST"
    fi
  done <<< "$REPAIR_ITEMS"
else
  log "Skipping repair — $ACTIVE_COUNT missions in flight"
fi

# 10. Final balance
FINAL=$(api GET /accounts/me | jq -r '.carrots')
log "Final balance: $FINAL carrots"
log "=== AUTO PLAY END ==="
echo "" >> "$LOG"
