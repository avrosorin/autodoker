#!/bin/sh

# Set the repository and branch as environment variables
REPO_NAME=$(basename "$repository" .git)
PORT="${PORT:-3000}"
NETWORK="${NETWORK:-reverseproxy}"
export REPO_NAME

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
    # try to stop and remove any existing containers
    docker-compose down
    # Run Docker Compose
    docker-compose up -d --build
    # check if stack is uo
    # Check if the stack is up
    if docker-compose ps | grep -q "Up"; then
        echo "Docker Compose stack is running."
    else
        echo "Docker Compose stack is not running."
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