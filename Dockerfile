FROM johnnypark/kafka-zookeeper:2.6.0 as kafka
FROM keycloak/keycloak:18.0.0 as keycloak

FROM alpine:latest

COPY --from=kafka /usr/bin/start-kafka.sh /usr/bin/start-kafka.sh
COPY --from=kafka /usr/bin/start-zookeeper.sh /usr/bin/start-zookeeper.sh
COPY --from=kafka /opt /opt
COPY --from=kafka /etc/supervisor.d/kafka.ini /etc/supervisor.d/kafka.ini
COPY --from=kafka /etc/supervisor.d/zookeeper.ini /etc/supervisor.d/zookeeper.ini

COPY --from=keycloak /opt/keycloak /opt/keycloak

RUN apk add --update supervisor openjdk11 bash gcompat gzip openssl tar which curl
### MongoDB
RUN echo 'http://dl-cdn.alpinelinux.org/alpine/v3.9/main' >> /etc/apk/repositories &&\
  echo 'http://dl-cdn.alpinelinux.org/alpine/v3.9/community' >> /etc/apk/repositories &&\
  apk update &&\
  apk add mongodb yaml-cpp=0.6.2-r2

COPY adoptions/realm-export.json /opt/keycloak/data/import/realm-export.json
COPY adoptions/keycloak-entrypoint.sh /tmp/keycloak-entrypoint.sh

COPY supervisord/keycloak.ini /etc/supervisor.d/keycloak.ini
COPY supervisord/mongo.ini /etc/supervisor.d/mongo.ini
RUN chmod a+x /tmp/keycloak-entrypoint.sh && mkdir -p /data/db

### Configs

ENV ZOOKEEPER_VERSION 3.4.13
ENV ZOOKEEPER_HOME /opt/zookeeper-"$ZOOKEEPER_VERSION"
ENV SCALA_VERSION 2.13
ENV KAFKA_VERSION 2.6.0
ENV KAFKA_HOME /opt/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION"

ENV ADVERTISED_HOST 127.0.0.1
ENV NUM_PARTITIONS 10

ENV KEYCLOAK_HOSTNAME localhost
ENV BIND localhost
ENV KEYCLOAK_ADMIN admin
ENV KEYCLOAK_ADMIN_PASSWORD admin

# 2181 is zookeeper, 9092 is kafka
EXPOSE 2181 9092
# keycloak 8080 (http) --> should be mapped to 9090
EXPOSE 8080
# MongoDB
EXPOSE 27017

ENTRYPOINT [ "supervisord" ]
CMD ["-n"]
