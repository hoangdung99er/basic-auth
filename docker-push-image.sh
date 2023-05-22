#!/bin/bash
docker push hoangdung99er/postgres-db:$1
docker push hoangdung99er/user-api:$1
docker push hoangdung99er/frontend:$1