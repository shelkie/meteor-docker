FROM zodern/meteor
LABEL maintainer="zodern"
USER root
RUN apt-get update && \
  apt-get install -y wget apt-utils gnupg libfontconfig1 libfreetype6 \
   && apt-get install -y wget gnupg ca-certificates \
     && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
     && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
     && apt-get update \
     # We install Chrome to get all the OS level dependencies, but Chrome itself
     # is not actually used as it's packaged in the node puppeteer library.
     # Alternatively, we could could include the entire dep list ourselves
     # (https://github.com/puppeteer/puppeteer/blob/master/docs/troubleshooting.md#chrome-headless-doesnt-launch-on-unix)
     # but that seems too easy to get out of date.
     && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*
  
# RUN export VERSION="2.1.1" && \
#  curl -L -o ./phantomjs.tar.bz2 https://github.com/Medium/phantomjs/releases/download/v$VERSION/phantomjs-$VERSION-linux-x86_64.tar.bz2 && \
#  mkdir phantomjs && \
#  tar xvjf phantomjs.tar.bz2 -C ./phantomjs --strip-components=1  && \
#  mv phantomjs /usr/local/share && \
#  ln -sf /usr/local/share/phantomjs/bin/phantomjs /usr/local/bin && \
#  rm -rf ./phantomjs ./phantomjs.tar.bz2


ONBUILD USER root
ONBUILD ARG NODE_VERSION='8.17.0'
ONBUILD ARG EXACT_NODE_VERSION=false
ONBUILD RUN bash ./scripts/onbuild-node.sh
ONBUILD ENV NODE_PATH=/home/app/.onbuild-node/lib/node_modules
ONBUILD ENV PATH=/home/app/.onbuild-node/bin:$PATH
ENTRYPOINT  bash /home/app/scripts/start.sh
