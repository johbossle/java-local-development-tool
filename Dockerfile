FROM johnnypark/kafka-zookeeper:2.6.0 as kafka
FROM keycloak/keycloak:22.0.5 as keycloak
FROM apicurio/apicurio-registry-mem:2.4.14.Final as apicurio

# Kafka and Zookeeper
FROM alpine:latest as custom-kafka

RUN apk add --update bash

ENV ZOOKEEPER_VERSION 3.9.1
ENV ZOOKEEPER_HOME /opt/zookeeper-"$ZOOKEEPER_VERSION"

RUN wget -q https://archive.apache.org/dist/zookeeper/zookeeper-"$ZOOKEEPER_VERSION"/apache-zookeeper-"$ZOOKEEPER_VERSION"-bin.tar.gz -O /tmp/zookeeper-"$ZOOKEEPER_VERSION".tgz
RUN ls -l /tmp/zookeeper-"$ZOOKEEPER_VERSION".tgz
RUN tar xfz /tmp/zookeeper-"$ZOOKEEPER_VERSION".tgz -C /opt && mv /opt/apache-zookeeper-"$ZOOKEEPER_VERSION"-bin /opt/zookeeper-"$ZOOKEEPER_VERSION" && rm /tmp/zookeeper-"$ZOOKEEPER_VERSION".tgz

ENV SCALA_VERSION 2.13
ENV KAFKA_VERSION 3.6.0
ENV KAFKA_HOME /opt/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION"
ENV KAFKA_DOWNLOAD_URL https://archive.apache.org/dist/kafka/"$KAFKA_VERSION"/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz

RUN wget -q $KAFKA_DOWNLOAD_URL -O /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz
RUN tar xfz /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz -C /opt && rm /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz


FROM alpine:latest

COPY --from=kafka /usr/bin/start-kafka.sh /usr/bin/start-kafka.sh
COPY --from=kafka /usr/bin/start-zookeeper.sh /usr/bin/start-zookeeper.sh
COPY --from=custom-kafka /opt /opt
COPY --from=kafka /etc/supervisor.d/kafka.ini /etc/supervisor.d/kafka.ini
COPY --from=kafka /etc/supervisor.d/zookeeper.ini /etc/supervisor.d/zookeeper.ini

COPY --from=keycloak /opt/keycloak /opt/keycloak

RUN apk add --update supervisor openjdk17 bash gcompat gzip openssl tar which curl
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

COPY --from=apicurio /deployments /apicurio
COPY adoptions/apicurio-entrypoint.sh /tmp/apicurio-entrypoint.sh
COPY supervisord/apicurio.ini /etc/supervisor.d/apicurio.ini

### Configs

ENV ZOOKEEPER_VERSION 3.9.1
ENV ZOOKEEPER_HOME /opt/zookeeper-"$ZOOKEEPER_VERSION"
COPY adoptions/zoo.cfg /opt/zookeeper-"$ZOOKEEPER_VERSION"/conf/zoo.cfg
ENV SCALA_VERSION 2.13
ENV KAFKA_VERSION 3.6.0
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
# Apicurio
EXPOSE 8081

ENTRYPOINT [ "supervisord" ]
CMD ["-n"]
