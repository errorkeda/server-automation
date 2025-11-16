#!/bin/bash
set -e


echo "===== UPDATE SCRIPT: pull, rebuild, restart ====="


BASE=~/deploy


# frontend
if [ -d "$BASE/frontend" ]; then
cd $BASE/frontend
git pull
if [ -f package.json ]; then
npm install
if npm run | grep -q "build"; then
npm run build
sudo rm -rf /var/www/html/*
sudo cp -r build/* /var/www/html/
fi
fi
fi


# backend
if [ -d "$BASE/backend" ]; then
cd $BASE/backend
git pull
npm install
pm2 restart backend || pm2 start ecosystem.config.js --only backend
pm2 save
fi


sudo systemctl reload nginx || true


echo "Update complete."