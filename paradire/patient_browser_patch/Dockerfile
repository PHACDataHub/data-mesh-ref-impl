# First stage: Clone and build the project
FROM node:latest AS build

# Install git, TypeScript, and other dependencies
RUN apt-get update && apt-get install -y git
RUN npm install -g typescript

# Set the working directory
WORKDIR /app

# Clone the patient-browser repository
RUN git clone https://github.com/smart-on-fhir/patient-browser.git .

# Copy patches from host to container
COPY . .

# Install dependencies and build project
RUN npm install colors request commander@2.15.1
RUN npm ci
RUN NODE_ENV=production npm run build

# Configure the browser
RUN mv default.json5 ./dist/config/

# Setup the nginx server
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
CMD ["sh", "-c", "nginx -g 'daemon off;'"]
