# Use a base image
FROM docker:latest

# Install Docker and Git
RUN apk update && apk add --no-cache git coreutils  && rm -rf /var/cache/apk/*
RUN apk update && apk add --no-cache git coreutils dateutils && rm -rf /var/cache/apk/*

# Set the working directory
WORKDIR /app

# Copy the deploy.sh script to the container
COPY deploy.sh .

# Make the script executable
RUN chmod +x deploy.sh

# Mount the host Docker to the image
VOLUME /var/run/docker.sock:/var/run/docker.sock

# Run the deploy.sh script
CMD ["./deploy.sh"]
