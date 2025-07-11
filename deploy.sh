sudo docker stop divinum-officium >/dev/null 2>&1 || true && \
sudo docker rm divinum-officium || true
sudo docker rm divinum-officium >/dev/null 2>&1 || true && \
sudo docker build --platform linux/arm64 -t divinum-officium . && \
sudo docker run -d -p 5057:5057 --name divinum-officium divinum-officium && \
sudo docker logs -f divinum-officium