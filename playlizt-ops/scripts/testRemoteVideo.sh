#!/bin/bash
echo "Testing Remote API..."

get_gateway_url() {
  local url
  url=$(cd playlizt-terraform && terraform output -raw api_gateway_url 2>/dev/null)
  if [ -z "$url" ]; then
    echo "Missing Terraform output: api_gateway_url" >&2
    exit 1
  fi
  echo "$url"
}

GATEWAY_URL=$(get_gateway_url)

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
