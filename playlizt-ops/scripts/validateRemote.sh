#!/bin/bash
echo "Validating Remote Services..."

test_health() {
  URL=$1
  NAME=$2
  echo -n "Testing $NAME ($URL)... "
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$URL")
  if [ "$HTTP_CODE" -eq 200 ]; then
    echo "OK"
  else
    echo "FAILED (Code: $HTTP_CODE)"
  fi
}

get_output() {
  local name=$1
  local value
  value=$(cd playlizt-terraform && terraform output -raw "$name" 2>/dev/null)
  if [ -z "$value" ]; then
    echo "Missing Terraform output: $name" >&2
    exit 1
  fi
  echo "$value"
}

GATEWAY_URL=$(get_output api_gateway_url)
AUTH_URL=$(get_output auth_service_url)
CONTENT_URL=$(get_output content_service_url)
PLAYBACK_URL=$(get_output playback_service_url)
AI_URL=$(get_output ai_service_url)

test_health "$GATEWAY_URL/actuator/health" "Gateway"
test_health "$AUTH_URL/actuator/health" "Auth"
test_health "$CONTENT_URL/actuator/health" "Content"
test_health "$PLAYBACK_URL/actuator/health" "Playback"
test_health "$AI_URL/actuator/health" "AI"

echo "Testing Auth Flow via Remote Gateway..."
# Register
echo "Registering remote user..."
curl -v -X POST -H "Content-Type: application/json" -d '{"username":"remoteuser","email":"remote@test.com","password":"password"}' "$GATEWAY_URL/api/v1/auth/register"

# Login and get Token
echo "Logging in..."
LOGIN_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d '{"email":"remote@test.com","password":"password"}' "$GATEWAY_URL/api/v1/auth/login")

if echo "$LOGIN_RESPONSE" | grep -q "token"; then
  echo "Login OK"
  TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
  echo "Token: ${TOKEN:0:10}..."
  
  # Test Content
  echo "Fetching Content..."
  curl -v -H "Authorization: Bearer $TOKEN" "$GATEWAY_URL/api/v1/content"
else
  echo "Login FAILED"
  echo "Response: $LOGIN_RESPONSE"
fi
