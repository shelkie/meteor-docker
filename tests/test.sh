set -e
docker build -t zodern/meteor ../image
docker build -t zodern/meteor:root ../root-image

command -v meteor >/dev/null 2>&1 || { curl https://install.meteor.com/ | sh; }

docker rm -f meteor-docker-test >/dev/null || true

sudo rm -rf /tmp/docker-meteor-tests
mkdir /tmp/docker-meteor-tests
cp -r ../ /tmp/docker-meteor-tests
cd /tmp/docker-meteor-tests/tests

rm -rf ./app
rm -rf ./bundle
rm -rf ./archive
mkdir ./app
mkdir ./bundle
mkdir ./archive

# Shows output whe the command fails
hide_output () {
  file='./command_logs.txt'
  rm -f "$file" || true
  set +e
  "$@"  > "$file" 2>&1
  code=$?
  set -e
  [ "$code" -eq 0 ] || cat "$file"

  return "$code"
 }

change_version() {
  echo "=> Creating app with ${1:-"latest Meteor version"}"

  cd ..
  rm -rf app
  hide_output meteor create $1 app
  cd app
  sleep 1

  echo "=> npm install babel-runtime"
  hide_output meteor npm install babel-runtime -q || true
}

build_app() {
  echo "=> Building app"
  sudo rm -rf /tmp/docker-meteor-tests/bundle || true
  meteor build ../bundle --debug
}

build_app_directory() {
  echo "=> Building app"
  meteor build --directory --debug ../bundle
}

test_bundle() {
  echo "=> Testing bundle volume"
  mv ../bundle/app.tar.gz ../bundle/bundle.tar.gz

  echo "==> Creating docker container"

  docker run \
    -v "$PWD"/../bundle:/bundle \
    -e "ROOT_URL=http://localhost.com" \
    -e "NPM_INSTALL_OPTIONS=--no-bin-links" \
    -e "MONGO_URL='none'" \
    -p 3000:3000 \
    -d \
    --name meteor-docker-test \
    "$DOCKER_IMAGE"
}

test_bundle_docker() {
  echo "=> Testing bundle image"
  NODE_VERSION=$(meteor node --version)

  echo "==> Creating image"
  mv ../bundle/app.tar.gz ../bundle/bundle.tar.gz  
  cd ../bundle

  cat > Dockerfile << EOT
FROM $DOCKER_IMAGE
COPY ./bundle.tar.gz /bundle/bundle.tar.gz
EOT

  hide_output docker build --build-arg NODE_VERSION="$NODE_VERSION" -t zodern/meteor-test .
  docker run --name meteor-docker-test \
  -e "ROOT_URL=http://app.com" \
  -p 3000:3000 \
  -d \
  zodern/meteor-test

  cd ../app
}

test_built_docker() {
  echo "=> Testing built_app image"
  NODE_VERSION=$(meteor node --version)

  echo "==> Creating image"

  cd ../bundle/bundle
  cat <<EOT > Dockerfile
FROM $DOCKER_IMAGE
COPY --chown=app:app . /built_app
RUN cd /built_app/programs/server && npm install $NPM_OPTIONS
EOT

  hide_output docker build --build-arg NODE_VERSION="$NODE_VERSION" -t zodern/meteor-test .
  docker run --name meteor-docker-test \
  -e "ROOT_URL=http://app.com" \
  -p 3000:3000 \
  -d \
  zodern/meteor-test

  cd ../../app
}

verify() {
  TIMEOUT=300
  elaspsed=0
  success=0

  while [[ "$elaspsed" != "$TIMEOUT" && $success == 0 ]]; do
    sleep 1
    elaspsed=$((elaspsed+1))

    curl -s \
      localhost:3000 >/dev/null \
      && success=1
            
  done

  if [ "$success" == "0" ]; then
    echo "FAIL"
    docker logs meteor-docker-test --tail 150
    exit 1
  fi

  echo "SUCCESS"
  docker rm -f meteor-docker-test >/dev/null || true
}

test_version() {
  change_version "$1"

  build_app
  test_bundle
  verify

  build_app
  test_bundle_docker
  verify

  build_app_directory
  test_built_docker "$1"
  verify
}

test_versions() {
  echo "--- Testing Docker Image $DOCKER_IMAGE ---"

  if [[ -z ${METEOR_TEST_OPTION+x} ]]; then
    test_version "--release=1.2.1"
    test_version "--release=1.3.5.1"
    # test_version "--release=1.4"
    # test_version "--release=1.4.4.5"
    test_version "--release=1.5.4.1"
    test_version "--release=1.6.1.4"
    test_version "--release=1.7.0.5"
    test_version "--release=1.8.1"
    test_version "--release=1.9.3"
    test_version "--release=1.10.2"
    test_version "--release=1.11.1"
    test_version "--release=2.0-beta.3"

    # Latest version
    test_version
  else
    test_version "$METEOR_TEST_OPTION"
  fi
}

DOCKER_IMAGE="zodern/meteor"
NPM_OPTIONS=""
test_versions

DOCKER_IMAGE="zodern/meteor:root"
NPM_OPTIONS="--unsafe-perm"
test_versions
