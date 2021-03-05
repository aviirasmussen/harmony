# tcp-proxy

Installs a TCP Proxy with stratum protocol V1 implementet. The proxy will translate to http and talk with an upstream HTTP pool agent

Supported scheme:

 - http for getwork mode (geth)
 - stratum+tcp for plain stratum mode


# http-agent

Installs a HTTP server that connects to a Harmony pool over HTTPS. Through the pool you can control under and overclocking, survilance and powercontrol. A HTTP agent is intended to be used in a sercure local network. A local server for ASIC machines that does a secure HTTPS connecttion to a Harmony pool.


## Reference installation

 - Ubuntu 20.04.1 LTS (Focal Fossa).

## Ubuntu
 - sudo apt update
 - sudo apt upgrade
 - sudo apt install net-tools
 - sudo apt install docker.io
 - sudo apt install <your choise if editor>
 - sudo systemctl enable --now docker
 - sudo usermod -aG docker <your ubuntu username>
 - sudo systemctl enable docker.service
 - sudo systemctl enable containerd.service
 - sudo systemctl start docker.servic

exit terminal and login again, then test your docker with the hello-world image

- docker run hello-world
 
## install docker-compose

- https://docs.docker.com/compose/install/

### check version

docker --version

## Docker containers

### Build harmony proxy image and start a container


 - docker build . -t tcp-proxy --build-arg HARMONY_GROUP=harmony --build-arg HARMONY_USER=harmony --no-cache
 - docker build . -t http-agent --build-arg HARMONY_GROUP=harmony --build-arg HARMONY_USER=harmony --no-cache

run container

- docker run --name tcp-proxy -v $PWD/src/:/home/harmony --hostname tcp-proxy -d --net host tcp-proxy
- docker run --name http-agent -v $PWD/src/:/home/harmony/app --hostname http-agent -d --net host http-agent

Check 

 - docker ps -a

Log into container

 - docker exec -i -t tcp-proxy /bin/bash
 - docker exec -i -t http-agent /bin/bash


### Build harmony/proxy and harmony/agent, see also .env file 

docker build . -t <tcp-proxy|http-agent> --build-arg HARMONY_GROUP=harmony --build-arg HARMONY_USER=harmony --no-cache  

### 
### Run Docker container
docker run --name <tcp-proxy|http-agent> --hostname <proxy|agent> --restart unless-stopped -d --net host <tcp-proxy|http-agent>
### Stop and Remove Docker image
 - docker stop <tcp-proxy|http-agent>
 - docker container rm -f <tcp-proxy|http-agent>
## Common docker commands used during development
### Show servers listing
netstat -tunlp
### Look at SIP messages 
sudo ngrep -d <your interface> -W byline port 5060
### Look at docker logs for the image
docker logs sentral
### Log into container
docker exec -i -t <proxy|agent> /bin/bash

### .env
Holds all environment variables for scripts, docker-compose AND containers
### templates
templates is the directory home for rulesets used by ASIC machines that connects to a pool container, for how to interact with a Harmony mining pool.
The directory gets mounted under your Harmony container. Every change under this directory will also therefore be reflected in a live Harmony container. Typical we will want to cahnge how a mining rigg will be over time - without making a a redeploy.
#### ./data/templates
### LICENSE
Harmony is distributed under the CC0 1.0 Universal [CREATIVE COMMONS license](LICENSE)
# Docker generic configuration for Harmony
 - All containers will be restarted automatically unless stopped manually
### docker-compose.yml
Holds service definitions for Harmony ASIC PC
#### Harmony
An Alpine Docker image running the Harmony ASIC PC engine using the Mojolicious web server
# Overview of common Docker commands used for Harmony ASIC PC engine during develpment and production runs
## docker-compose config
Outputs the docker-compose.yml file with correctly mapped environment
## docker-compose up -d
Starts the Harmony and Db containers detached.
## docker-compose down
Stops the containers
## docker exec -i -t <tcp-proxy|http-agent> /bin/bash
Opens an interactive bash shell inside a harmony container

