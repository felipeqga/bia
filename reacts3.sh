#!/bin/bash
function build() {
    API_URL=$1
    echo $API_URL
    cd bia
    npm install
    echo " Iniciando build..."
    NODE_OPTIONS=--openssl-legacy-provider VITE_API_URL=$API_URL SKIP_PREFLIGHT_CHECK=true npm run build --prefix client
    echo " Build finalizado..."
    cd ..
}
