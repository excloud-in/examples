sudo apt remove -y $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1)
sudo apt-get install -y uidmap
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
# Don't install rootless because compose has certain things like setting ulimits which only rooted docker can do.
# dockerd-rootless-setuptool.sh install
# sudo loginctl enable-linger ubuntu
