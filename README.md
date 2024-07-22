A repository for building a working environment for zephyr-based projects development.

Component versions:
zephyr-sdk: 0.16.8
openocd: 0.12.0

```
docker container list
docker build -t zephyr-devcontainer .
docker run -it zephyr-devcontainer
docker rmi -f $(docker images -aq)
```