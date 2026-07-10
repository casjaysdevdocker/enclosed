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
dockerHome="/srv/$USER/docker/casjaysdevdocker/enclosed/enclosed/latest/rootfs"
mkdir -p "/srv/$USER/docker/enclosed/rootfs"
git clone "https://github.com/dockermgr/enclosed" "$HOME/.local/share/CasjaysDev/dockermgr/enclosed"
cp -Rfva "$HOME/.local/share/CasjaysDev/dockermgr/enclosed/rootfs/." "$dockerHome/"
docker run -d \
--restart always \
--privileged \
--name casjaysdevdocker-enclosed-latest \
--hostname enclosed \
-e TZ=${TIMEZONE:-America/New_York} \
-v "$dockerHome/data:/data:z" \
-v "$dockerHome/config:/config:z" \
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
      - "/srv/$USER/docker/casjaysdevdocker/enclosed/enclosed/latest/rootfs/data:/data:z"
      - "/srv/$USER/docker/casjaysdevdocker/enclosed/enclosed/latest/rootfs/config:/config:z"
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
