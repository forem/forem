#!/usr/bin/env bash

if [ ! -f .env ]; then
    echo "Creating .env file"
    cp .env_sample .env
fi

echo "Updating .env file with codespace specific values"
sed -i "s/DATABASE_URL=.*/DATABASE_URL=postgres:\/\/postgres:postgres@postgres:5432/g" .env
sed -i "s/DATABASE_URL_TEST=.*/DATABASE_URL_TEST=postgres:\/\/postgres:postgres@postgres:5432/g" .env
sed -i "s/REDIS_URL=.*/REDIS_URL=redis:\/\/redis:6379/g" .env
