> You can preview your project using the following console commands:

## Updating the database information

```bash
# replace following values in .env if needed
# SQLHOST = database.XXXXXXXXXXXX.us-east-1.rds.amazonaws.com
# SQLPORT = 3306
# SQLSCHM = CLONEID

vim .env

```

<<<<<<< HEAD
## Installing pnpm if needed
=======
## Installing pnpm
>>>>>>> master

```bash

curl -fsSL https://get.pnpm.io/install.sh | sh -
# or see https://pnpm.io/installation

```


## Installing project dependencies

```bash

<<<<<<< HEAD
npm i
=======
pnpm i
>>>>>>> master

```


## Building

```bash

<<<<<<< HEAD
npm run build
=======
pnpm run build
>>>>>>> master

```

## Preview project

```bash

<<<<<<< HEAD
npm run preview
=======
pnpm run preview
>>>>>>> master

# Project will be accessible through port 4173 in your browser

```

<<<<<<< HEAD
> Or You can use a dockerized version of the project using the dockerize script
=======
> Or You can use a dockerized version of the project using the following console commands:
>>>>>>> master

## Updating the database information

```bash
# replace following values in .env if needed
# SQLHOST = database.XXXXXXXXXXXX.us-east-1.rds.amazonaws.com
# SQLPORT = 3306
# SQLSCHM = CLONEID

vim .env

```

<<<<<<< HEAD
=======
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
>>>>>>> master
