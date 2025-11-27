#!/bin/bash
echo "Validating Local Services..."

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

test_health "http://localhost:4761/actuator/health" "Eureka"
test_health "http://localhost:4081/actuator/health" "Auth"
test_health "http://localhost:4082/actuator/health" "Content"
test_health "http://localhost:4083/actuator/health" "Playback"
test_health "http://localhost:4084/actuator/health" "AI"
test_health "http://localhost:4080/actuator/health" "Gateway"

echo "Testing Auth Flow via Gateway..."
# Register
echo "Registering testuser..."
curl -s -X POST -H "Content-Type: application/json" -d '{"username":"testuser","email":"test@test.com","password":"password"}' http://localhost:4080/api/v1/auth/register | grep "success" && echo "Register OK" || echo "Register FAILED"

# Login
echo "Logging in..."
curl -s -X POST -H "Content-Type: application/json" -d '{"email":"test@test.com","password":"password"}' http://localhost:4080/api/v1/auth/login | grep "token" && echo "Login OK" || echo "Login FAILED"
