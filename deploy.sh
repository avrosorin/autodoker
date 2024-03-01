#!/bin/sh

# Set the repository and branch as environment variables
repository="$REPO"
branch="$BRANCH"
token="$AUTH"
repo_name=$(basename "$repository" .git)
container_port="${rPORT:-3000}"
network="${NETWORK:-reverseproxy}"

# Check if Docker Compose is available
if ! command -v docker-compose >/dev/null 2>&1; then
    echo "Docker Compose is not installed. Please install Docker Compose and try again."
    exit 1
fi

# SWITCH WORKING DIR
cd "/app" || { echo "Failed to change to repository directory"; exit 1; }

# Clone the repository if it doesn't exist
git clone "https://$token@github.com/$repository.git" "/repo" || { echo "Failed to clone repository"; exit 1; }

# Change to the repository directory
cd "/repo" || { echo "Failed to change to repository directory"; exit 1; }

# Checkout the specified branch
git checkout "$branch" || { echo "Failed to checkout branch"; exit 1; }

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
image_name="$repo_name-$branch"
docker build -t "$image_name" .

container_name="$repo_name:$branch"

# Check if the container is running
if docker ps -a --format '{{.Names}}' | grep -q "$image_name"; then
    # Stop the container
    docker stop "$image_name"
    # Remove the container
    docker rm "$image_name"
fi

# Check if the network exists or create it
if ! docker network inspect $network >/dev/null 2>&1; then
    docker network create $network
fi

docker run -d -p $container_port:$container_port -h $image_name --name $image_name $image_name
docker network connect $network $image_name

# Exit successfully
exit 0