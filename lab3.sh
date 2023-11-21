#!/bin/bash

# Запуск контейнера с веб-сервером nginx на порту 8080
echo "[@] Запуск контейнера с веб-сервером nginx на порту 8080"
docker run -it -d --name nginx -p 8080:80 nginx

sleep 1

# Выполнение Apache Benchmark 
echo "[@] Выполнение Apache Benchmark"
ab -n 30000 -c 1000  http://127.0.0.1:8080//