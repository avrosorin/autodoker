# Use a base image
FROM docker:latest

# Install Docker and Git
RUN apk update && apk add --no-cache git


# Set the working directory
WORKDIR /app

# Copy the deploy.sh script to the container
COPY deploy.sh .

# Make the script executable
RUN chmod +x deploy.sh

# Mount the host Docker to the image
VOLUME /var/run/docker.sock:/var/run/docker.sock

# ENV $REPO=
# ENV $BRANCH=
# ENV $AUTH=

# Run the deploy.sh script
CMD ["./deploy.sh"]
