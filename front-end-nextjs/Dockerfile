# syntax=docker/dockerfile:1

# Comments are provided throughout this file to help you get started.
# If you need more help, visit the Dockerfile reference guide at
# https://docs.docker.com/go/dockerfile-reference/

# Want to help us make this template better? Share your feedback here: https://forms.gle/ybq9Krt8jtBL3iCk7

ARG NODE_VERSION=20.15.0

FROM node:${NODE_VERSION}-alpine

# Use develoment node environment by default.
ENV NODE_ENV development


WORKDIR /usr/src/app


# Copy package.json and package-lock.json first to leverage Docker cache
COPY package*.json ./

# Install dependencies
RUN npm install


# Install additional dependencies
RUN npm install tailwindcss postcss autoprefixer

# Copy the rest of the source files into the image.
COPY . .

# Change the ownwership of the app directory
RUN chown -R node:node /usr/src/app


# Run the application as a non-root user.
USER node


# Expose the port that the application listens on.
EXPOSE 3000

# Run the application.
CMD ["npm", "run", "dev"]
