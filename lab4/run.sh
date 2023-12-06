#!/bin/bash
sudo docker-compose up -d
sudo ab -n 30000 -c 7000  http://localhost:80/

