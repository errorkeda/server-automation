#!/bin/bash
set -e

echo "===== FULL MERN AUTO DEPLOY START ====="

# Update system
sudo apt update -y

# Install Git
if ! command -v git &> /dev/null; then
    echo "Installing Git..."
    sudo apt install git -y
fi

# Install curl + build tools
sudo apt install curl build-essential -y

# Install Node.js (LTS)
if ! command -v node &> /dev/null; then
    echo "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install nodejs -y
fi

# Install PM2
if ! command -v pm2 &> /dev/null; then
    echo "Installing PM2..."
    sudo npm install pm2 -g
fi

# Install Nginx
if ! command -v nginx &> /dev/null; then
    echo "Installing Nginx..."
    sudo apt install nginx -y
    sudo systemctl enable nginx
    sudo systemctl start nginx
fi

# Ensure Nginx folders exist (failsafe)
sudo mkdir -p /etc/nginx/sites-available
sudo mkdir -p /etc/nginx/sites-enabled

echo ""
echo "Enter your FRONTEND Git repo URL:"
read FRONTEND_REPO

echo ""
echo "Enter your BACKEND Git repo URL:"
read BACKEND_REPO

# Create deployment folders
mkdir -p ~/deploy
cd ~/deploy

echo "Cloning frontend..."
git clone $FRONTEND_REPO frontend || { cd frontend && git pull; }

echo "Cloning backend..."
git clone $BACKEND_REPO backend || { cd backend && git pull; }

# FRONTEND BUILD
cd ~/deploy/frontend
npm install
npm run build || echo "⚠️ Warning: Frontend build failed"

sudo mkdir -p /var/www/html
sudo rm -rf /var/www/html/*
sudo cp -r build/* /var/www/html/

# BACKEND SETUP
cd ~/deploy/backend
npm install

# create default .env if missing
if [ ! -f ".env" ]; then
    echo "PORT=5000" > .env
fi

pm2 stop backend || true
pm2 start index.js --name backend
pm2 save
pm2 startup

# NGINX CONFIG
echo "Configuring Nginx..."

sudo tee /etc/nginx/sites-available/mern > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    root /var/www/html;
    index index.html;

    location / {
        try_files \$uri /index.html;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:5000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/mern /etc/nginx/sites-enabled/mern
sudo nginx -t
sudo systemctl restart nginx

echo ""
echo "===== DONE ====="
echo "Frontend: http://YOUR_EC2_IP"
echo "Backend API: http://YOUR_EC2_IP/api"
echo "To update later: run update.sh"
