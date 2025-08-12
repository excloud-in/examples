if command -v docker >/dev/null 2>&1; then
    echo "Docker is installed"
else
    echo "Docker is not installed Installing...."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
fi

sudo usermod -aG docker "$(whoami)"
echo "🔄 Updating group membership..."
newgrp docker <<EONG
echo "✅ Docker is ready to use without sudo."
docker --version
EONG

sudo mkdir -p /var/frappe/
ADMIN_PASSWORD=$(openssl rand -hex 18)
if [ -f /var/frappe/admin-password ]; then
    echo "Using admin-password at /var/frappe/admin-password"
    ADMIN_PASSWORD=$(cat /var/frappe/admin-password)
else
    echo "Generating new admin password"
    echo $ADMIN_PASSWORD > /tmp/admin-password
    sudo mv /tmp/admin-password /var/frappe/admin-password 
fi

sed -i s/\${ADMIN_PASSWORD}/${ADMIN_PASSWORD}/g compose.yaml

sudo docker compose -f compose.yaml up -d

start=$(date +%s)

count=0
while [ "$count" -lt 3 ]; do
  if [ "$(curl -m 1 -s -o /dev/null -w '%{http_code}' http://localhost:8080)" == "200" ];then
    count=$(( count+1 ))
    continue
  fi
  count=0
  elapsed=$(( $(date +%s) - start ))
  printf "\rWaiting for ERPNext to bootstrap... %ds" "$elapsed"
  sleep 1
done

echo -e "\n\n----Installation complete----"
echo "Admin Login: Administrator/${ADMIN_PASSWORD}"
echo "DB Login: root/${ADMIN_PASSWORD}"
echo "URL: http://$(curl -s -4 ip.wtf):8080"
