# Reference OS 
Ubuntu
# Ubuntu postinstall
sudo apt update
sudo apt upgrade
sudo apt install docker.io
sudo apt install emacs
sudo systemctl enable --now docker
sudo usermod -aG docker harmony
docker --version
## verify docker running for user harmony
docker run hello-world

# harmony
Local server for Stratum clients
ddd
