# IozyTest en un seul conteneur : le serveur Node sert le front construit,
# l'API et Socket.IO sous un même préfixe (/test par défaut), pour vivre à
# côté d'IozyCore derrière son nginx. Le préfixe se change à la construction
# (--build-arg IOZYTEST_BASE_PATH=...) : le front est compilé avec, le serveur
# le lit à l'exécution, les deux restent d'accord.
#
# Construit depuis la racine de CE dépôt. La charte IozyKit est une dépendance
# épinglée sur un tag (archive du dépôt IozyKit, voir package.json) : npm la
# télécharge, rien n'est copié d'un dossier voisin.

# --- Construction du front ---
FROM node:22-alpine AS build
WORKDIR /build
ARG IOZYTEST_BASE_PATH=/test
ENV IOZYTEST_BASE_PATH=$IOZYTEST_BASE_PATH
COPY package.json package-lock.json ./
RUN npm ci
COPY . ./
RUN npm run build

# --- Exécution ---
FROM node:22-alpine
WORKDIR /app
ENV NODE_ENV=production
COPY package.json package-lock.json ./
RUN npm ci --omit=dev
COPY server ./server
# Le jeu de données livré ; un volume monté sur /app/data le reprend au
# premier démarrage puis garde les questions ajoutées.
COPY data ./data
COPY --from=build /build/dist ./dist
ARG IOZYTEST_BASE_PATH=/test
ENV IOZYTEST_BASE_PATH=$IOZYTEST_BASE_PATH     IOZYTEST_STATIC_DIR=/app/dist     PORT=3001
EXPOSE 3001
CMD ["node", "server/index.js"]
