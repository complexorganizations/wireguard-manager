FROM debian:stable-slim

RUN apt-get update && apt-get install -y wireguard qrencode iproute2 &&     apt-get clean

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]