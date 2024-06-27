> You can preview your project using the following console commands:

## Updating the database information

```bash
# replace following values in .env if needed
# SQLHOST = database.XXXXXXXXXXXX.us-east-1.rds.amazonaws.com
# SQLPORT = 3306
# SQLSCHM = CLONEID

vim .env

```

## Installing pnpm

```bash

curl -fsSL https://get.pnpm.io/install.sh | sh -
# or see https://pnpm.io/installation

```


## Installing project dependencies

```bash

pnpm i

```


## Building

```bash

pnpm run build

```

## Preview project

```bash

pnpm run preview

# Project will be accessible through port 4173 in your browser

```

> Or You can use a dockerized version of the project using the following console commands:

## Updating the database information

```bash
# replace following values in .env if needed
# SQLHOST = database.XXXXXXXXXXXX.us-east-1.rds.amazonaws.com
# SQLPORT = 3306
# SQLSCHM = CLONEID

vim .env

```

## Build the the docker Image

```bash

# install pnpm (see above), then

pnpm run docker:build
# or
docker build . -t cloneid-module1

```

## Preview project

```bash

pnpm run docker:run
# or
docker run --rm --name=cloneid-module1 -p 4173:4173 cloneid-module1

# Project will be accessible on localhost, through port 4173 in your browser

```
