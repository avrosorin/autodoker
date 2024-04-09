#!/bin/sh

# Set the repository and branch as environment variables
REPO_NAME=$(basename "$REPO" .git)
PORT="${PORT:-3000}"
NETWORK="${NETWORK:-reverseproxy}"

#PREPARE SERVICE NAME
SERVICE_NAME=$(echo "$REPO_NAME-$BRANCH" | sed 's/[^a-z0-9_-]//g')
export SERVICE_NAME

# Check if Docker Compose is available
if ! command -v docker-compose >/dev/null 2>&1; then
    echo "Docker Compose is not installed. Please install Docker Compose and try again."
    exit 1
fi

# SWITCH WORKING DIR
cd "/app" || { echo "Failed to change to repository directory"; exit 1; }

# Clone the repository if it doesn't exist
git clone "https://$AUTH@github.com/$REPO.git" "/repo" || { echo "Failed to clone repository"; exit 1; }

# Change to the repository directory
cd "/repo" || { echo "Failed to change to repository directory"; exit 1; }

# Checkout the specified branch
git checkout "$BRANCH" || { echo "Failed to checkout branch"; exit 1; }

# Check if the docker-compose.yaml file exists
if [ -f "docker-compose.yaml" ]; then
    echo "docker-compose.yaml file found. Running Docker Compose."
    # Get the current image ID before building a new one
    CURRENT_IMAGE_ID=$(docker images -q "$SERVICE_NAME")
    echo "Current Image ID: $CURRENT_IMAGE_ID"

    # Run Docker Compose
    docker-compose up -d --build --force-recreate

    echo "Checking if the stack is up and running"

    # Check if the stack is up
    if docker-compose ps | grep -q "Up"; then
        # Get the start time of the Docker container
        SERVICE_STATRT_TIME=$(docker inspect --format='{{.State.StartedAt}}' $(docker-compose ps -q))
        START_TIME=$(date -d "$SERVICE_STATRT_TIME" +%s) 
        # Get the current time
        CURRENT_TIME=$(date +%s)
        # Calculate the duration in seconds
        DURATION=$(echo "$CURRENT_TIME - $START_TIME" | tr -d '\r' | bc -l)
        echo "Stack up for: $DURATION seconds"
        # Check if the duration is less than 1 minute (60 seconds)
        if [ $DURATION -lt 60 ]; then
            echo "Stack is freshly deployed. Build successful."
            echo "Removing previous image to cleanup"
            docker rmi -f "$CURRENT_IMAGE_ID"
            exit 0
        fi
    else
        echo "Docker Compose could not deploy the image succesfully."
        exit 1;
    fi
    exit 0;
else
    echo "docker-compose.yaml file not found. Looking to build dockerfile"
fi

# Run any additional commands or scripts here
IMAGE_NAME="$REPO_NAME-$BRANCH"
docker build -t "$IMAGE_NAME" .

container_name="$REPO_NAME:$branch"

# Check if the container is running
if docker ps -a --format '{{.Names}}' | grep -q "$IMAGE_NAME"; then
    # Stop the container
    docker stop "$IMAGE_NAME"
    # Remove image
    docker image rm -f "$IMAGE_NAME:latest"
    # Remove the container
    docker rm "$IMAGE_NAME"
fi

# Check if the network exists or create it
if ! docker network inspect $NETWORK >/dev/null 2>&1; then
    docker network create $NETWORK
fi

docker run -d -p $PORT:$PORT -h $IMAGE_NAME --name $IMAGE_NAME $IMAGE_NAME
docker network connect $NETWORK $IMAGE_NAME

if docker ps -a --format '{{.Names}}' | grep -q "$IMAGE_NAME"; then
    echo "Container is running"
    exit 0;
    else
    echo "Container is not running"
    exit 1;
fi