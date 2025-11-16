#!/bin/bash
# copy build to nginx root
FRONT_BUILD_DIR="build"
if [ -d "$FRONT_BUILD_DIR" ]; then
echo "Copying frontend build to /var/www/html"
sudo rm -rf /var/www/html/*
sudo cp -r "$FRONT_BUILD_DIR"/* /var/www/html/
else
echo "Warning: expected "$FRONT_BUILD_DIR" directory not found. Check your frontend build output."
fi


# Nginx config
echo "\n===== NGINX CONFIG ====="
NGINX_CONF="/etc/nginx/sites-available/mern"
sudo bash -c "cat > $NGINX_CONF" <<EOL
server {
listen 80;
server_name ${DOMAIN:-_};


root /var/www/html;
index index.html index.htm;


# Security headers
add_header X-Frame-Options "DENY" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "no-referrer-when-downgrade" always;


# Gzip & cache (static files)
gzip on;
gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;


location /api/ {
proxy_pass http://127.0.0.1:${BACKEND_PORT}/;
proxy_http_version 1.1;
proxy_set_header Upgrade \$http_upgrade;
proxy_set_header Connection 'upgrade';
proxy_set_header Host \$host;
proxy_set_header X-Real-IP \$remote_addr;
proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto \$scheme;
}


location / {
try_files \$uri /index.html;
}
}
EOL


sudo ln -sf $NGINX_CONF /etc/nginx/sites-enabled/mern
sudo nginx -t
sudo systemctl restart nginx


echo "\n===== DONE ====="
echo "Frontend served from /var/www/html (nginx)"
echo "Backend running under PM2 as 'backend' on port $BACKEND_PORT and proxied at /api/"
echo "To change env, edit ~/deploy/backend/.env and then run: pm2 restart backend"