## 👋 Welcome to enclosed 🚀  

enclosed README  
  
  
## Install my system scripts  

```shell
 sudo bash -c "$(curl -q -LSsf "https://github.com/systemmgr/installer/raw/main/install.sh")"
 sudo systemmgr --config && sudo systemmgr install scripts  
```
  
## Automatic install/update  
  
```shell
dockermgr update enclosed
```
  
## Install and run container
  
```shell
mkdir -p "$HOME/.local/share/srv/docker/enclosed/rootfs"
git clone "https://github.com/dockermgr/enclosed" "$HOME/.local/share/CasjaysDev/dockermgr/enclosed"
cp -Rfva "$HOME/.local/share/CasjaysDev/dockermgr/enclosed/rootfs/." "$HOME/.local/share/srv/docker/enclosed/rootfs/"
docker run -d \
--restart always \
--privileged \
--name casjaysdevdocker-enclosed \
--hostname enclosed \
-e TZ=${TIMEZONE:-America/New_York} \
-v "$HOME/.local/share/srv/docker/casjaysdevdocker-enclosed/rootfs/data:/data:z" \
-v "$HOME/.local/share/srv/docker/casjaysdevdocker-enclosed/rootfs/config:/config:z" \
-p 80:80 \
casjaysdevdocker/enclosed:latest
```
  
## via docker-compose  
  
```yaml
version: "2"
services:
  ProjectName:
    image: casjaysdevdocker/enclosed
    container_name: casjaysdevdocker-enclosed
    environment:
      - TZ=America/New_York
      - HOSTNAME=enclosed
    volumes:
      - "$HOME/.local/share/srv/docker/casjaysdevdocker-enclosed/rootfs/data:/data:z"
      - "$HOME/.local/share/srv/docker/casjaysdevdocker-enclosed/rootfs/config:/config:z"
    ports:
      - 80:80
    restart: always
```
  
## Get source files  
  
```shell
dockermgr download src casjaysdevdocker/enclosed
```
  
OR
  
```shell
git clone "https://github.com/casjaysdevdocker/enclosed" "$HOME/Projects/github/casjaysdevdocker/enclosed"
```
  
## Build container  
  
```shell
cd "$HOME/Projects/github/casjaysdevdocker/enclosed"
buildx 
```
  
## Authors  
  
🤖 casjay: [Github](https://github.com/casjay) 🤖  
⛵ casjaysdevdocker: [Github](https://github.com/casjaysdevdocker) [Docker](https://hub.docker.com/u/casjaysdevdocker) ⛵  
