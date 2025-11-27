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

test_health "https://api-gateway-a2y2msttda-bq.a.run.app/actuator/health" "Gateway"
test_health "https://auth-service-a2y2msttda-bq.a.run.app/actuator/health" "Auth"
test_health "https://content-service-a2y2msttda-bq.a.run.app/actuator/health" "Content"
test_health "https://playback-service-a2y2msttda-bq.a.run.app/actuator/health" "Playback"
test_health "https://ai-service-a2y2msttda-bq.a.run.app/actuator/health" "AI"

echo "Testing Auth Flow via Remote Gateway..."
# Register
echo "Registering remote user..."
curl -v -X POST -H "Content-Type: application/json" -d '{"username":"remoteuser","email":"remote@test.com","password":"password"}' https://api-gateway-a2y2msttda-bq.a.run.app/api/v1/auth/register

# Login
echo "Logging in..."
curl -v -X POST -H "Content-Type: application/json" -d '{"email":"remote@test.com","password":"password"}' https://api-gateway-a2y2msttda-bq.a.run.app/api/v1/auth/login
