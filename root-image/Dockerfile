FROM zodern/meteor
LABEL maintainer="zodern"
USER root
RUN apt-get update && \
  apt-get install -y gnupg libfontconfig1 libfreetype6 \
  && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
    && apt-get install -y google-chrome-stable fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf libxss1 \
      --no-install-recommends \
  rm -rf /var/lib/apt/lists/*
  
# RUN export VERSION="2.1.1" && \
#  curl -L -o ./phantomjs.tar.bz2 https://github.com/Medium/phantomjs/releases/download/v$VERSION/phantomjs-$VERSION-linux-x86_64.tar.bz2 && \
#  mkdir phantomjs && \
#  tar xvjf phantomjs.tar.bz2 -C ./phantomjs --strip-components=1  && \
#  mv phantomjs /usr/local/share && \
#  ln -sf /usr/local/share/phantomjs/bin/phantomjs /usr/local/bin && \
#  rm -rf ./phantomjs ./phantomjs.tar.bz2

RUN npm init -y &&  \
    npm i puppeteer \
    # Add user so we don't need --no-sandbox.
    # same layer as npm install to keep re-chowned files from using up several hundred MBs more space
    && groupadd -r pptruser && useradd -r -g pptruser -G audio,video pptruser \
    && mkdir -p /home/pptruser/Downloads \
    && chown -R pptruser:pptruser /home/pptruser \
    && chown -R pptruser:pptruser /node_modules \
    && chown -R pptruser:pptruser /package.json \
    && chown -R pptruser:pptruser /package-lock.json

# Run everything after as non-privileged user.
USER pptruser

CMD ["google-chrome-stable"]

ONBUILD USER root
ONBUILD ARG NODE_VERSION='8.17.0'
ONBUILD ARG EXACT_NODE_VERSION=false
ONBUILD RUN bash ./scripts/onbuild-node.sh
ONBUILD ENV NODE_PATH=/home/app/.onbuild-node/lib/node_modules
ONBUILD ENV PATH=/home/app/.onbuild-node/bin:$PATH
ENTRYPOINT  bash /home/app/scripts/start.sh
