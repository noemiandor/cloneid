FROM --platform=linux/amd64 clid-m2-backend-conda-m2:v1


LABEL iteration="1"

ARG SHELL=/bin/bash
ENV SHELL=/bin/bash


ARG PATH="/usr/local/lib/nodejs/node-v20.11.1-linux-x64/bin:${PATH}"
ENV PATH="/usr/local/lib/nodejs/node-v20.11.1-linux-x64/bin:${PATH}"


RUN apt-get clean all && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        cron curl awscli\
    && apt-get clean all && \
    apt-get purge && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


ENV VERSION=v20.11.1
ENV DISTRO=linux-x64
RUN wget https://nodejs.org/dist/v20.11.1/node-v20.11.1-linux-x64.tar.xz
RUN mkdir -p /usr/local/lib/nodejs
RUN tar -xJvf node-$VERSION-$DISTRO.tar.xz -C /usr/local/lib/nodejs 
RUN rm node-$VERSION-$DISTRO.tar.xz

RUN echo 'export PATH="/usr/local/lib/nodejs/node-v20.11.1-linux-x64/bin:$PATH"'  >> /root/.bashrc

RUN ln -s /usr/local/lib/nodejs/node-$VERSION-$DISTRO/bin/node /usr/bin/node
RUN ln -s /usr/local/lib/nodejs/node-$VERSION-$DISTRO/bin/npm /usr/bin/npm
RUN ln -s /usr/local/lib/nodejs/node-$VERSION-$DISTRO/bin/npx /usr/bin/npx

RUN npm install -g pm2

WORKDIR /cron

COPY cron .
RUN chmod 0700 *.sh
RUN chmod 0600 cronfile
RUN cat cronfile >> /etc/crontab

WORKDIR /root/R
COPY R .

WORKDIR /root/scripts
COPY scripts .
RUN chmod 0700 *.sh 

WORKDIR /root/node
COPY node .
RUN rm -rf node_modules && npm i

WORKDIR /root

CMD ["/root/scripts/startup.sh"]