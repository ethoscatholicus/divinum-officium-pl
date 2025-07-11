#!/bin/bash

# Check if deploy.cfg exists
if [ -f deploy.cfg ]; then
    source deploy.cfg
else
    # Ask for port number
    read -p "Podaj numer portu (domyślnie 80): " PORT
    PORT=${PORT:-80}
    
    # Save to config file
    echo "PORT=$PORT" > deploy.cfg

	# Update ports.conf
	sed -i "s/^Listen .*/Listen $PORT/" ./docker/apache/ports.conf

fi
# Stop and remove existing container
sudo docker stop divinum-officium >/dev/null 2>&1 || true && \
sudo docker rm divinum-officium >/dev/null 2>&1 || true

# Build and run new container
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) PLATFORM="linux/amd64" ;;
    aarch64) PLATFORM="linux/arm64" ;;
    *) echo "Nieobsługiwana architektura: $ARCH"; exit 1 ;;
esac

sudo docker build --platform $PLATFORM -t divinum-officium . && \
sudo docker run -d -p $PORT:$PORT --name divinum-officium divinum-officium && \
sudo docker logs -f divinum-officium