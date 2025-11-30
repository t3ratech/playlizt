#!/bin/bash
echo "Testing Remote API..."
# Get Gateway URL from Terraform or use hardcoded
GATEWAY_URL=$(cd terraform && terraform output -raw api_gateway_url 2>/dev/null)
if [ -z "$GATEWAY_URL" ]; then
    GATEWAY_URL="https://api-gateway-a2y2msttda-bq.a.run.app"
fi

echo "Gateway: $GATEWAY_URL"

echo "Fetching Content..."
RESPONSE=$(curl -s "$GATEWAY_URL/api/v1/content")
echo "Response: $RESPONSE"

if echo "$RESPONSE" | grep -q "videoUrl"; then
    echo "✅ Video Content Found!"
else
    echo "❌ Video Content NOT Found."
    exit 1
fi
