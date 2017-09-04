#!/bin/bash

docker-compose build;
docker-compose up -d db;
sleep 60;
docker-compose up -d koel;