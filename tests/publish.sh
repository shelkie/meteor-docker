set -e
VERSION="$1"

# Normal image
docker tag shelkie/meteor shelkie/meteor:latest
docker tag shelkie/meteor shelkie/meteor:$VERSION

docker push shelkie/meteor:latest
docker push shelkie/meteor:$VERSION

# root image
docker tag shelkie/meteor:root shelkie/meteor:$VERSION-root

docker push shelkie/meteor:root
docker push shelkie/meteor:$VERSION-root
