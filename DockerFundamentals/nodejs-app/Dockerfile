# Plain single-stage build on the full node:20 image.
# Kept deliberately "naive" so its size can be compared against the
# multi-stage alpine build in ../../DockerFiles&Images/.
FROM node:20

WORKDIR /app

# Manifests first: this layer is cached and only re-runs when deps change
COPY package*.json ./
RUN npm install

# Then the application source
COPY . .

EXPOSE 3000
CMD ["npm", "start"]
