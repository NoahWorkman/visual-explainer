#!/bin/bash

# Share Visual Explainer HTML via Cloudflare R2
# Usage: ./share.sh <html-file>
# Returns: Live URL at staging.cquenced.com

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

HTML_FILE="${1}"

if [ -z "$HTML_FILE" ]; then
    echo -e "${RED}Error: Please provide an HTML file to share${NC}" >&2
    echo "Usage: $0 <html-file>" >&2
    exit 1
fi

if [ ! -f "$HTML_FILE" ]; then
    echo -e "${RED}Error: File not found: $HTML_FILE${NC}" >&2
    exit 1
fi

# Read R2 credentials from ~/.claude.json
CLAUDE_JSON="$HOME/.claude.json"
if [ ! -f "$CLAUDE_JSON" ]; then
    echo -e "${RED}Error: ~/.claude.json not found. R2 credentials required.${NC}" >&2
    exit 1
fi

S3_ACCESS_KEY_ID=$(python3 -c "import json; c=json.load(open('$CLAUDE_JSON')); print(c['mcpServers']['s3']['env']['S3_ACCESS_KEY_ID'])" 2>/dev/null)
S3_SECRET_ACCESS_KEY=$(python3 -c "import json; c=json.load(open('$CLAUDE_JSON')); print(c['mcpServers']['s3']['env']['S3_SECRET_ACCESS_KEY'])" 2>/dev/null)

if [ -z "$S3_ACCESS_KEY_ID" ] || [ -z "$S3_SECRET_ACCESS_KEY" ]; then
    echo -e "${RED}Error: R2 credentials not found in ~/.claude.json (mcpServers.s3.env)${NC}" >&2
    exit 1
fi

# Generate a unique key under shared-visuals/
BASENAME=$(basename "$HTML_FILE" .html)
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
R2_KEY="shared-visuals/${BASENAME}-${TIMESTAMP}.html"

echo -e "${CYAN}Sharing $(basename "$HTML_FILE")...${NC}" >&2

# Upload to R2 via boto3
set +e
RESULT=$(S3_ACCESS_KEY_ID="$S3_ACCESS_KEY_ID" S3_SECRET_ACCESS_KEY="$S3_SECRET_ACCESS_KEY" python3 -c "
import boto3
from botocore.config import Config
import json, os

s3 = boto3.client('s3',
    endpoint_url='https://ea56583a004d44621d7583d358786a86.r2.cloudflarestorage.com',
    aws_access_key_id=os.environ['S3_ACCESS_KEY_ID'],
    aws_secret_access_key=os.environ['S3_SECRET_ACCESS_KEY'],
    region_name='auto',
    config=Config(signature_version='s3v4')
)

filepath = '$HTML_FILE'
key = '$R2_KEY'

with open(filepath, 'rb') as f:
    s3.put_object(Bucket='cquenced-staging', Key=key, Body=f, ContentType='text/html')

url = f'https://staging.cquenced.com/{key}'
print(json.dumps({'url': url, 'key': key, 'size': os.path.getsize(filepath)}))
" 2>&1)
UPLOAD_EXIT=$?
set -e

if [ $UPLOAD_EXIT -ne 0 ]; then
    echo -e "${RED}Error: Upload failed${NC}" >&2
    echo "$RESULT" >&2
    exit 1
fi

# Extract URL
LIVE_URL=$(echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin)['url'])" 2>/dev/null)

if [ -z "$LIVE_URL" ]; then
    echo -e "${RED}Error: Upload failed${NC}" >&2
    echo "$RESULT" >&2
    exit 1
fi

echo "" >&2
echo -e "${GREEN}Shared successfully!${NC}" >&2
echo "" >&2
echo -e "${GREEN}Live URL: ${LIVE_URL}${NC}" >&2
echo "" >&2

# Output JSON for programmatic use
echo "$RESULT"
