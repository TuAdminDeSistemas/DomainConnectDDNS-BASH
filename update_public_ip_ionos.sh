#!/bin/bash

# Configuration
API_KEY="public.private"
DOMAINS=("domain1.es" "subdomain1.eu" "subdomain2.com")  # List of domains and subdomains
IP_FILE="current_ip.txt"
telegramBotToken='token_telegram' #OPTIONAL
telegramChatID='chatid' #OPTIONAL

# Function to send Telegram messages
function talkToBot() {
    message=$1
    curl -s -X POST https://api.telegram.org/bot${telegramBotToken}/sendMessage -d text="${message}" -d chat_id=${telegramChatID} > /dev/null 2>&1
}

# Step 1: Get the public IP
IP=$(curl -s https://checkip.amazonaws.com)
echo "The Public IP is: $IP"

# Step 2: Check if the IP has changed
if [ -f "$IP_FILE" ]; then
    PREVIOUS_IP=$(cat "$IP_FILE")
else
    PREVIOUS_IP=""
fi

if [ "$IP" != "$PREVIOUS_IP" ]; then
    echo "IP has changed from $PREVIOUS_IP to $IP"
    echo "$IP" > "$IP_FILE"  # Save the new IP to the file

    # Get the zone ID
    ZONE_ID=$(curl -s -X 'GET' \
      'https://api.hosting.ionos.com/dns/v1/zones' \
      -H 'accept: application/json' \
      -H "X-API-Key: $API_KEY" | jq -r ".[] | select(.name == \"${DOMAINS[0]}\") | .id")

    echo "The zone ID is: $ZONE_ID"

    # Step 3: Get the existing records for each domain and delete the old ones
    for DOMAIN in "${DOMAINS[@]}"; do
      # List all records
      ALL_RECORDS=$(curl -s -X 'GET' \
        "https://api.hosting.ionos.com/dns/v1/zones/$ZONE_ID" \
        -H 'accept: application/json' \
        -H "X-API-Key: $API_KEY" | jq ".records[] | select(.name == \"$DOMAIN\" and .type == \"A\")")

      # Extract all IDs from records except the most recent one
      IDS=($(echo "$ALL_RECORDS" | jq -r '.id'))
      CONTENTS=($(echo "$ALL_RECORDS" | jq -r '.content'))

      # Delete all records except the most recent
      for i in "${!IDS[@]}"; do
        if [ "${CONTENTS[$i]}" != "$IP" ]; then
          echo "Deleting old record with ID: ${IDS[$i]} for $DOMAIN"
          curl -s -X 'DELETE' \
            "https://api.hosting.ionos.com/dns/v1/zones/$ZONE_ID/records/${IDS[$i]}" \
            -H 'accept: */*' \
            -H "X-API-Key: $API_KEY" > /dev/null
        fi
      done

      # Update the DNS record with the new IP
      RESPONSE=$(curl -s -X 'POST' \
        "https://api.hosting.ionos.com/dns/v1/zones/$ZONE_ID/records" \
        -H 'accept: application/json' \
        -H "X-API-Key: $API_KEY" \
        -H 'Content-Type: application/json' \
        -d "[{
          \"name\": \"$DOMAIN\",
          \"type\": \"A\",
          \"content\": \"$IP\",
          \"ttl\": 3600,
          \"prio\": 0,
          \"disabled\": false
        }]" | jq)

      # Show answer
      echo "Output update $DOMAIN: $RESPONSE"
    done

    # Step 4: Send message via Telegram with all updated domains
    DOMAINS_UPDATED=$(printf "%s%%0A" "${DOMAINS[@]}")  # We use %0A for line breaks in Telegram
    talkToBot "The IP has changed to $IP. DNS records have been updated for the following domains:%0A$DOMAINS_UPDATED"
else
    echo "The IP has not changed. No action required."
fi