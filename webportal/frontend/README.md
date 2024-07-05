> You can preview your project using the following console commands:

## Updating the database information

```bash
# replace following values in .env if needed
# SQLHOST = database.XXXXXXXXXXXX.us-east-1.rds.amazonaws.com
# SQLPORT = 3306
# SQLSCHM = CLONEID

vim .env

```

## Installing pnpm if needed

```bash

curl -fsSL https://get.pnpm.io/install.sh | sh -
# or see https://pnpm.io/installation

```


## Installing project dependencies

```bash

npm i

```


## Building

```bash

npm run build

```

## Preview project

```bash

npm run preview

# Project will be accessible through port 4173 in your browser

```

> Or You can use a dockerized version of the project using the dockerize script

## Updating the database information

```bash
# replace following values in .env if needed
# SQLHOST = database.XXXXXXXXXXXX.us-east-1.rds.amazonaws.com
# SQLPORT = 3306
# SQLSCHM = CLONEID

vim .env

```

