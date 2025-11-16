#!/bin/bash
set -e

echo "===== UPDATING PROJECT ====="

cd ~/deploy/frontend
git pull
npm install
npm run build
sudo rm -rf /var/www/html/*
sudo cp -r build/* /var/www/html/

cd ~/deploy/backend
git pull
npm install
pm2 restart backend

echo "===== UPDATE DONE ====="
