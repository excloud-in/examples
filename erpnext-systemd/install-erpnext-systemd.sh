sudo apt-get update -y

sudo apt-get install -y \
    valkey-server \
    pkg-config \
    mariadb-server \
    libmariadb-dev \
    libmariadb-dev-compat \
    build-essential \
    xvfb \
    libfontconfig \
    fontconfig \
    xfonts-75dpi

sudo ln -s  /usr/bin/valkey-server /usr/bin/redis-server

wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb
sudo dpkg -i wkhtmltox_0.12.6.1-2.jammy_amd64.deb

sudo apt --fix-broken install -y


curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
source ~/.bashrc
nvm install 24
npm install -g yarn


curl -LsSf https://astral.sh/uv/0.10.9/install.sh | sh
source $HOME/.local/bin/env
uv python install 3.14 --default
uv tool install frappe-bench

bench init frappe-bench --frappe-branch v16.10.10
