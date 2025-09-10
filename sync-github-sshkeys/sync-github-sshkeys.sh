#!/bin/bash
# Interactive installer for GitHub SSH key sync

set -euo pipefail

SCRIPT_PATH="/usr/local/bin/sync-github-sshkeys.sh"
CRON_LOG="/var/log/sync-github-sshkeys.log"
TOKEN_FILE="/root/.github-token"

# --- 1. Ask for token ---
if [ ! -f "$TOKEN_FILE" ]; then
  echo "To create GitHub Personal Access Token visit https://github.com/settings/tokens"
  read -rsp "Enter your GitHub Personal Access Token (with read:org scope): " GITHUB_TOKEN
  echo
  echo "$GITHUB_TOKEN" > "$TOKEN_FILE"
  chmod 600 "$TOKEN_FILE"
else
  GITHUB_TOKEN=$(cat "$TOKEN_FILE")
fi

# --- 2. List orgs ---
echo "Fetching organizations..."
orgs=$(curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user/orgs | jq -r '.[].login')

if [ -z "$orgs" ]; then
  echo "❌ No organizations found or token invalid."
  exit 1
fi

echo "Select an organization:"
select GITHUB_ORG in $orgs; do
  [ -n "$GITHUB_ORG" ] && break
done

# --- 3. List teams ---
echo "Fetching teams for org $GITHUB_ORG..."
teams=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/orgs/$GITHUB_ORG/teams" | jq -r '.[].slug')

if [ -z "$teams" ]; then
  echo "❌ No teams found in org $GITHUB_ORG"
  exit 1
fi

echo "Select a team:"
select GITHUB_TEAM_SLUG in $teams; do
  [ -n "$GITHUB_TEAM_SLUG" ] && break
done

# --- 4. Install sync script ---
cat > "$SCRIPT_PATH" <<"EOF"
#!/bin/bash
# Sync SSH keys for root user from GitHub team members

set -euo pipefail

TOKEN_FILE="/root/.github-token"
GITHUB_ORG="{{ORG}}"
GITHUB_TEAM_SLUG="{{TEAM}}"
ROOT_AUTH_KEYS="/root/.ssh/authorized_keys"
TMP_KEYS="/tmp/github_team_keys.$$"

if [ ! -f "$TOKEN_FILE" ]; then
  echo "❌ Missing token file at $TOKEN_FILE" >&2
  exit 1
fi
GITHUB_TOKEN=$(cat "$TOKEN_FILE")

if ! command -v jq >/dev/null 2>&1; then
  echo "❌ jq is required." >&2
  exit 1
fi

# Fetch team members
page=1
members=()
while :; do
  response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/orgs/$GITHUB_ORG/teams/$GITHUB_TEAM_SLUG/members?page=$page&per_page=100")
  count=$(echo "$response" | jq length)
  [ "$count" -eq 0 ] && break
  members+=($(echo "$response" | jq -r '.[].login'))
  page=$((page+1))
done

# Collect keys
> "$TMP_KEYS"
for user in "${members[@]}"; do
  echo "Fetching keys for $user..."
  curl -s "https://github.com/$user.keys" >> "$TMP_KEYS"
done

# Deduplicate
sort -u "$TMP_KEYS" -o "$TMP_KEYS"

# Backup old keys
if [ -f "$ROOT_AUTH_KEYS" ]; then
  cp "$ROOT_AUTH_KEYS" "$ROOT_AUTH_KEYS.bak.$(date +%s)"
fi

# Replace with new keys
cat "$TMP_KEYS" > "$ROOT_AUTH_KEYS"
chmod 600 "$ROOT_AUTH_KEYS"
rm -f "$TMP_KEYS"

echo "✅ Keys synced for team $GITHUB_TEAM_SLUG in org $GITHUB_ORG"
EOF

# Replace placeholders
sed -i "s/{{ORG}}/$GITHUB_ORG/" "$SCRIPT_PATH"
sed -i "s/{{TEAM}}/$GITHUB_TEAM_SLUG/" "$SCRIPT_PATH"

chmod 700 "$SCRIPT_PATH"

# --- 5. Install cronjob ---
(crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH" ; echo "0 * * * * $SCRIPT_PATH >> $CRON_LOG 2>&1") | crontab -

echo "✅ Installed sync script for team '$GITHUB_TEAM_SLUG' in org '$GITHUB_ORG'"
echo "✅ Cronjob set (hourly)"
echo "➡️ Running first sync..."
$SCRIPT_PATH >> $CRON_LOG 2>&1
echo "✅ First sync done. Check log: $CRON_LOG"

echo "Your GitHub Team Member SSH keys can be used to login to ssh root@server_ip"
