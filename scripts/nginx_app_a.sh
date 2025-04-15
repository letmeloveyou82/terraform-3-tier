#!/bin/bash

# 1. NAT 게이트웨이 통한 인터넷 연결 확인
until curl -s --head http://google.com | grep "200 OK" > /dev/null; do
  echo "[network] Waiting for NAT gateway to route traffic..."
  sleep 3
done
echo "[network] Internet is accessible via NAT!"

# 2. apt update & nginx + mysql-client 설치 (최대 5회 재시도)
for i in {1..5}; do
  echo "[apt] Try $i: updating and installing packages..."
  apt update -y && apt install -y nginx mysql-client && break
  echo "[apt] Attempt $i failed, retrying in 5 seconds..."
  sleep 5
done

# 3. nginx 설정 - 8080 포트로 수정
sed -i 's/listen 80 default_server;/listen 8080 default_server;/' /etc/nginx/sites-available/default

# 4. AZ 정보 출력 (App A or C에 따라 다르게 표시)
echo "<h1>App Tier A (8080 OK)</h1>" > /var/www/html/index.html

# 5. nginx 부팅 시 자동 실행 + 시작
systemctl enable nginx
systemctl restart nginx

