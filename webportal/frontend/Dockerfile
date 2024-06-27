FROM  node:latest
EXPOSE 4173
EXPOSE 3000
EXPOSE 24678
SHELL ["/bin/bash", "-c"]

WORKDIR /root

RUN mkdir -p /root/.ssh
COPY sshkeys/id_rsa.pub /root/.ssh/authorized_keys
COPY sshkeys/id_rsa /root/.ssh/id_rsa
RUN chown root:root /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys
RUN chown root:root /root/.ssh/id_rsa && chmod 600 /root/.ssh/id_rsa

RUN mkdir -p /root/.ssh
COPY sshkeys/authorized_keys /root/.ssh/authorized_keys
RUN chown root:root /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys
COPY sshkeys/id_rsa /root/.ssh/id_rsa
RUN chown root:root /root/.ssh/id_rsa && chmod 600 /root/.ssh/id_rsa
COPY sshkeys/config /root/.ssh/config
RUN chown root:root /root/.ssh/config && chmod 600 /root/.ssh/config
RUN rm /etc/update-motd.d/*
RUN echo "ENABLED=0" > /etc/default/motd-news
RUN echo > /etc/motd
RUN sed -i 's/^.*pam_motd.so/#/' /etc/pam.d/login


RUN apt update
RUN apt -y upgrade
RUN apt-get install -y --no-install-recommends apt-utils
RUN apt-get install -y --no-install-recommends git wget ssh ca-certificates
RUN apt-get install -y --no-install-recommends net-tools
RUN wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash 
RUN wget -qO- https://get.pnpm.io/install.sh | bash -


WORKDIR /app
COPY package-lock.json ./
ADD . ./
RUN npm ci
RUN npm run build
CMD npm run preview --host

