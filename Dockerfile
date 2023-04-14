FROM node:18-alpine
WORKDIR /frontend
COPY package*.json ./
RUN npm install
#RUN npm audit fix --force
RUN yarn add react-scripts
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
## run start
