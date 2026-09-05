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

# Read bot mode
MODE_FILE="/root/bunny/bot-mode.json"
BOT_MODE="konservatif"
if [ -f "$MODE_FILE" ]; then
  BOT_MODE=$(jq -r '.mode // "konservatif"' "$MODE_FILE")
fi
log "Bot mode: $BOT_MODE"

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
# Requires: 3 dust_tuft, 1 plank, 2 rope + 40 carrots fee
SLINGSHOT_EVENT=$(echo "$EVENTS" | jq -r '.events[] | select(.templateKey == "onboarding_craft_slingshot" and .completedAt == null)')
if [ -n "$SLINGSHOT_EVENT" ]; then
  log "  Checking materials for Slingshot..."
  INV_NOW=$(api GET /inventory)
  DUST=$(echo "$INV_NOW" | jq '[.materials[] | select(.key == "dust_tuft") | .quantity] | add // 0')
  PLANK=$(echo "$INV_NOW" | jq '[.materials[] | select(.key == "plank") | .quantity] | add // 0')
  ROPE=$(echo "$INV_NOW" | jq '[.materials[] | select(.key == "rope") | .quantity] | add // 0')
  log "    Have: dust_tuft=$DUST/3, plank=$PLANK/1, rope=$ROPE/2"

  # Buy more timber if need more dust_tuft (timber gives fiber+straw+dust_tuft on missions)
  # Craft planks if needed (requires timber)
  if [ "$PLANK" -lt 1 ]; then
    TIMBER=$(echo "$INV_NOW" | jq '[.materials[] | select(.key == "timber") | .quantity] | add // 0')
    if [ "$TIMBER" -gt 0 ]; then
      log "    Crafting 1 Plank..."
      RESULT=$(api POST "/items/plank/craft")
      STATUS=$(echo "$RESULT" | jq -r '.error // empty')
      if [ -z "$STATUS" ]; then
        PLANK=1
        log "    Plank crafted"
      else
        log "    Craft Plank failed: $STATUS"
      fi
    else
      log "    No timber to craft Plank — buying..."
      for i in 1 2 3; do
        api POST "/items/timber/buy" '{"quantity":1}' > /dev/null
      done
      RESULT=$(api POST "/items/plank/craft")
      STATUS=$(echo "$RESULT" | jq -r '.error // empty')
      if [ -z "$STATUS" ]; then
        PLANK=1
        log "    Plank crafted after buying timber"
      fi
    fi
  fi

  # Craft ropes if needed (requires fiber)
  if [ "$ROPE" -lt 2 ]; then
    NEEDED=$((2 - ROPE))
    INV_NOW=$(api GET /inventory)
    FIBER=$(echo "$INV_NOW" | jq '[.materials[] | select(.key == "fiber") | .quantity] | add // 0')
    if [ "$FIBER" -ge "$NEEDED" ]; then
      log "    Crafting $NEEDED Ropes..."
      for i in $(seq 1 $NEEDED); do
        RESULT=$(api POST "/items/rope/craft")
      done
      ROPE=$((ROPE + NEEDED))
      log "    Ropes crafted"
    else
      log "    Not enough fiber ($FIBER) for ropes — buying timber..."
      for i in $(seq 1 $((NEEDED * 2))); do
        api POST "/items/timber/buy" '{"quantity":1}' > /dev/null
      done
      for i in $(seq 1 $NEEDED); do
        RESULT=$(api POST "/items/rope/craft")
      done
      ROPE=$((ROPE + NEEDED))
      log "    Ropes crafted after buying timber"
    fi
  fi

  # Check dust_tuft — need 3, may need more from missions/buying
  INV_NOW=$(api GET /inventory)
  DUST=$(echo "$INV_NOW" | jq '[.materials[] | select(.key == "dust_tuft") | .quantity] | add // 0')
  PLANK=$(echo "$INV_NOW" | jq '[.materials[] | select(.key == "plank") | .quantity] | add // 0')
  ROPE=$(echo "$INV_NOW" | jq '[.materials[] | select(.key == "rope") | .quantity] | add // 0')

  if [ "$DUST" -ge 3 ] && [ "$PLANK" -ge 1 ] && [ "$ROPE" -ge 2 ]; then
    log "  Materials ready! Crafting Slingshot..."
    RESULT=$(api POST "/items/slingshot/craft")
    STATUS=$(echo "$RESULT" | jq -r '.error // empty')
    if [ -z "$STATUS" ]; then
      log "  Slingshot crafted!"
      # Claim reward
      EVENTS=$(api GET /events)
      EVENT_ID=$(echo "$EVENTS" | jq -r '.events[] | select(.templateKey == "onboarding_craft_slingshot") | .id')
      if [ -n "$EVENT_ID" ]; then
        api POST "/events/$EVENT_ID/claim" > /dev/null
        log "  Claimed: Craft Slingshot → +375 carrots"
      fi
    else
      log "  Craft Slingshot failed: $STATUS"
    fi
  else
    log "  Not enough materials for Slingshot (dust_tuft=$DUST/3, plank=$PLANK/1, rope=$ROPE/2) — will try next run"
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

# Repair any item (reward: 200 carrots) — skip items with 0 durability (broken beyond repair)
REPAIR_EVENT=$(echo "$EVENTS" | jq -r '.events[] | select(.templateKey == "onboarding_repair_item" and .completedAt == null)')
if [ -n "$REPAIR_EVENT" ]; then
  REPAIRABLE=$(api GET /inventory | jq -r '.equipment[] | select(.durability > 0 and .durability < .maxDurability) | .id' | head -1)
  if [ -n "$REPAIRABLE" ]; then
    RESULT=$(api POST "/inventory/$REPAIRABLE/repair")
    STATUS=$(echo "$RESULT" | jq -r '.error // empty')
    if [ -z "$STATUS" ]; then
      log "  Repaired item for onboarding"
      EVENT_ID=$(echo "$EVENTS" | jq -r '.events[] | select(.templateKey == "onboarding_repair_item") | .id')
      if [ -n "$EVENT_ID" ]; then
        api POST "/events/$EVENT_ID/claim" > /dev/null
        log "  Claimed: Repair Item → +200 carrots"
      fi
    else
      log "  Onboarding repair failed: $STATUS"
    fi
  else
    log "  No repairable items (all broken items have 0 durability)"
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

  # Mission selection based on bot mode
  if [ "$BOT_MODE" = "agresif" ]; then
    # Agresif mode: accept ALL missions, prioritize high reward, no cost limit
    log "  [AGRESIF] No cost limit — accepting all profitable missions"
    MISSIONS=$(api GET /zones/sunny_meadow | jq -c '[.missions[] | select(.pinned == true or .entryCost <= '"$CARROTS"')] | sort_by(.mobPower) | reverse | sort_by(.entryCost)[]')
  else
    # Konservatif mode: free first, skip >15 carrots, sort by cost then mobPower
    log "  [KONSERVATIF] Prioritas gratis, skip >15 carrots"
    MISSIONS=$(api GET /zones/sunny_meadow | jq -c '[.missions[] | select(.pinned == true or .entryCost <= '"$CARROTS"')] | sort_by(.mobPower) | sort_by(.entryCost)[]')
  fi

  while read mission; do
    if [ "$AVAILABLE_SLOTS" -le 0 ]; then break; fi

    MID=$(echo "$mission" | jq -r '.id')
    MNAME=$(echo "$mission" | jq -r '.name')
    COST=$(echo "$mission" | jq -r '.entryCost')
    MOB=$(echo "$mission" | jq -r '.mobPower')

    # Mode-based cost filtering
    if [ "$BOT_MODE" = "agresif" ]; then
      # Agresif: no cost limit, accept anything we can afford
      if (( $(echo "$COST > $CARROTS" | bc -l) )); then
        continue
      fi
    else
      # Konservatif: skip expensive missions (>15 carrots) unless free
      if (( $(echo "$COST > 15" | bc -l) )); then
        continue
      fi
    fi

    # Check if we can afford it
    if (( $(echo "$COST <= $CARROTS" | bc -l) )); then
      ACCEPT=$(api POST "/missions" '{"boardMissionId":"'"$MID"'"}')
      STATUS=$(echo "$ACCEPT" | jq -r '.status // "error"')
      CHANCE=$(echo "$ACCEPT" | jq -r '.successChance // 0')
      if [ "$STATUS" = "in_progress" ]; then
        CHANCE_PCT=$(echo "$CHANCE * 100" | bc 2>/dev/null || echo "?")
        log "Accepted: $MNAME (mob:$MOB, cost:$COST, chance:${CHANCE_PCT}%) [$BOT_MODE]"
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
# Skip items with 0 durability (broken beyond repair, needs patch_scraps material)
ACTIVE_COUNT=$(api GET "/missions?status=in_progress" | jq '.missions | length')
if [ "$ACTIVE_COUNT" -eq 0 ]; then
  log "No active missions — repairing gear..."
  INVENTORY=$(api GET /inventory)
  PATCH_SCRAPS=$(echo "$INVENTORY" | jq '[.materials[] | select(.key == "patch_scraps") | .quantity] | add // 0')
  REPAIR_ITEMS=$(echo "$INVENTORY" | jq -c '.equipment[] | select(.equippedBunnyId != null and .durability > 0 and .durability < .maxDurability * 0.5)')
  if [ -n "$REPAIR_ITEMS" ]; then
    while read item; do
      IID=$(echo "$item" | jq -r '.id')
      INAME=$(echo "$item" | jq -r '.name')
      DUR=$(echo "$item" | jq -r '.durability')
      MAX=$(echo "$item" | jq -r '.maxDurability')
      REPAIR_COST=$(( (MAX - DUR) ))
      if [ "$PATCH_SCRAPS" -lt 2 ]; then
        log "  Skip repair $INAME — not enough patch_scraps ($PATCH_SCRAPS)"
        continue
      fi
      REPAIR=$(api POST "/inventory/$IID/repair")
      COST=$(echo "$REPAIR" | jq -r '.fee // 0')
      STATUS=$(echo "$REPAIR" | jq -r '.error // empty')
      if [ -n "$STATUS" ]; then
        log "  Repair failed $INAME ($DUR/$MAX): $STATUS"
      else
        log "  Repaired $INAME ($DUR/$MAX) → cost: $COST"
        PATCH_SCRAPS=$((PATCH_SCRAPS - 2))
      fi
    done <<< "$REPAIR_ITEMS"
  else
    log "  No gear needs repair (durability > 50%)"
  fi
else
  log "Skipping repair — $ACTIVE_COUNT missions in flight"
fi

# 10. Final balance
FINAL=$(api GET /accounts/me | jq -r '.carrots')
log "Final balance: $FINAL carrots"
log "=== AUTO PLAY END ==="
echo "" >> "$LOG"
