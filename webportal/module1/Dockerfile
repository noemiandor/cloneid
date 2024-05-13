FROM --platform=linux/amd64 rocker/r-ubuntu:latest

ARG BUILD_INFO
ARG BUILD_DATE
ARG BUILD_VERSION
ARG BUILD_ARCH

ENV AUTHOR_FNAME=Daniel \
    AUTHOR_LNAME=Hannaby

LABEL maintainer="${AUTHOR_FNAME} ${AUTHOR_LNAME} <legwork_02land@icloud.com>"
LABEL info=$BUILD_INFO

LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.label-schema.name="cloneid-module1"
LABEL org.label-schema.description="Cloneid Module1"
LABEL org.label-schema.url="https://www.cloneredesign.com"
LABEL org.label-schema.vcs-url="https://github.com/noemiandor/cloneid"
LABEL org.label-schema.vendor="${AUTHOR_FNAME} ${AUTHOR_LNAME}"
LABEL org.label-schema.version=$BUILD_VERSION
LABEL org.label-schema.architecture=$BUILD_ARCH
LABEL org.label-schema.docker.cmd="docker run --rm -ti -p 4173:4173 cloneid-module1:latest"

LABEL iteration="1"

RUN apt-get clean all && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -yq \
        libhdf5-dev \
        libcurl4-gnutls-dev \
        libssl-dev \
        libxml2-dev \
        libpng-dev \
        libxt-dev \
        zlib1g-dev \
        libbz2-dev \
        liblzma-dev \
        libglpk40 \
        libgit2-dev \
        openjdk-8-jdk-headless \
        libmagick++-6.q16-dev \
        libmysqlclient-dev \
        libproj22 \
        libgdal-dev \
        vim \
        git \
    && apt-get clean all && \
    apt-get purge && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN Rscript -e "install.packages(c( 'rmarkdown' ));"
RUN Rscript -e "install.packages(c( 'tidyverse' ));"
RUN Rscript -e "install.packages(c( 'workflowr' ));"
RUN Rscript -e "install.packages(c( 'BiocManager' ));"
ARG bioc_ver=3.19
RUN Rscript -e "BiocManager::install(version = '${bioc_ver}', ask = FALSE)"
RUN Rscript -e "BiocManager::install('biomaRt');"
RUN Rscript -e "install.packages(c( 'qualV' ));"
RUN Rscript -e "install.packages(c( 'RColorBrewer' ));"
RUN Rscript -e "install.packages(c( 'gtools' ));"
RUN Rscript -e "install.packages(c( 'gplots' ));"
RUN Rscript -e "install.packages(c( 'gdata' ));"
RUN Rscript -e "install.packages(c( 'RMySQL' ));"
RUN Rscript -e "install.packages(c( 'flexclust'));"
RUN Rscript -e "install.packages(c( 'Matrix' ));"
RUN Rscript -e "install.packages(c( 'matlab' ));"
RUN Rscript -e "install.packages(c( 'yaml' ));"
RUN Rscript -e "install.packages(c( 'magick' ));"
RUN Rscript -e "install.packages(c( 'raster' ));"
RUN Rscript -e "install.packages(c( 'ape' ));"
RUN Rscript -e "install.packages(c( 'liayson' ));"
RUN Rscript -e "install.packages(c( 'umap' ));"
RUN Rscript -e "install.packages(c( 'R.utils' ));"
RUN Rscript -e "install.packages(c( 'tictoc' ));"
RUN Rscript -e "install.packages('https://cran.r-project.org/src/contrib/Archive/reticulate/reticulate_1.22.tar.gz',repos=NULL, type='source')"

WORKDIR /home/docker

RUN cd /home/docker && wget  https://github.com/noemiandor/cloneid/archive/refs/heads/master.zip && unzip master.zip && rm master.zip && mv cloneid-master cloneid
RUN chown -R docker:docker /home/docker/cloneid

RUN export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64; R CMD javareconf
RUN export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64; cd /home/docker/cloneid; ./gradlew uberJar; cp build/libs/cloneid.jar rpackage/inst/java/cloneid.jar
RUN export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64; cd /home/docker/cloneid; R CMD build rpackage
RUN Rscript -e "install.packages(c('rJava'));"
RUN export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64; cd /home/docker/cloneid; R CMD INSTALL cloneid_1.2.1.tar.gz


RUN apt update && apt -yq install curl gnupg wget
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
RUN apt-get install -y nodejs
WORKDIR /app

ADD . ./
RUN rm -rf node_modules .svelte-kit build package-lock.json
RUN npm i
RUN npm run build
EXPOSE 4173
CMD npm run preview