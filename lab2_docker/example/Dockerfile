FROM amytabb/docker_ubuntu16_essentials
ENV NAME VAR1
COPY run.sh /run.sh
COPY main.cpp /main.cpp
WORKDIR /
RUN g++ -o main main.cpp
CMD ["/bin/sh", "/run.sh"]