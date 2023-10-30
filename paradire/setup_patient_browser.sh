#!/bin/bash
set -e

# Note, FHIR server must be running and available on localhost:8080 prior to running
# this script.

curr_dir=$(pwd)

has_node=$(which node)

if [ -z "$has_node" ]; then
    sudo apt install nodejs -y
fi

cd 

if [ ! -d "patient-browser" ]; then
    sudo npm install typescript -g
    git clone https://github.com/smart-on-fhir/patient-browser.git
    ## Install dependencies and build project
    (cd patient-browser && NODE_ENV=production npm install colors request commander@2.15.1 && npm ci && NODE_ENV=production npm run build)
fi

cd patient-browser

# Configure browser
rm -f ./dist/config/*.json5
mkdir ./config
echo "Generating config, please wait..."
node config-genrator/generate_config.js --server http://127.0.0.1:8080/fhir --file default
sleep 1
mv config/default.json5 ./dist/config/
rm -rf ./config
# Disable the broken fihr-viewer
sed -i 's/enabled: true/enabled: false/g' ./dist/config/default.json5

# Create a dockerfile
cat <<EOL > Dockerfile
FROM nginx:alpine
COPY ./dist /usr/share/nginx/html
CMD ["sh", "-c", "nginx -g 'daemon off;'"]
EOL

# Build docker image
docker build . -t patient-browser

# Start browser
docker run -d --restart always --name patient-browser -p 9090:80  patient-browser 

echo "Patient browser started on http://localhost:9090"

cd $curr_dir
