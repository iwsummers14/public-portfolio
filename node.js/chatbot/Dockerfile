#define image to build QYigd6cgMVVNwyTzKs81XZtTFuRwJOcDdBg7AU0mXVyNbs7O5RH2zdv
FROM node:11

#Create app directory
WORKDIR /usr/src/chatbot

#Install app dependencies
#wildcard is used to ensure both package.json and package-lock.json are copied
COPY package*.json ./

RUN npm install
#If this was a production build, use:
# RUN npm ci --only=production

#bundle the source files
COPY . .

#if a port opening was needed, put it here
#EXPOSE 8080 for example

#command to run
CMD ["npm", "start"]
