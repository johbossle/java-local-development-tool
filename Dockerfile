FROM keycloak/keycloak:22.0.5 as keycloak
FROM apicurio/apicurio-registry-mem:2.4.14.Final as apicurio

FROM alpine:latest

RUN apk add --update supervisor openjdk17 bash gcompat gzip openssl tar which curl

### MongoDB
RUN echo 'http://dl-cdn.alpinelinux.org/alpine/v3.9/main' >> /etc/apk/repositories &&\
  echo 'http://dl-cdn.alpinelinux.org/alpine/v3.9/community' >> /etc/apk/repositories &&\
  apk update &&\
  apk add mongodb yaml-cpp=0.6.2-r2

### Kafka
ENV SCALA_VERSION 2.13
ENV KAFKA_VERSION 3.6.0
ENV KAFKA_HOME /opt/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION"
ENV KAFKA_DOWNLOAD_URL https://archive.apache.org/dist/kafka/"$KAFKA_VERSION"/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz

RUN wget -q $KAFKA_DOWNLOAD_URL -O /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz
RUN tar xfz /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz -C /opt && rm /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz

### Keycloak
COPY --from=keycloak /opt/keycloak /opt/keycloak

### Apicurio
COPY --from=apicurio /deployments /apicurio

### Adoptions
COPY adoptions/apicurio-entrypoint.sh /tmp/apicurio-entrypoint.sh
COPY adoptions/kafka-entrypoint.sh /tmp/kafka-entrypoint.sh
COPY adoptions/kafka.server.properties $KAFKA_HOME/config/kraft/server.properties
COPY adoptions/keycloak-entrypoint.sh /tmp/keycloak-entrypoint.sh
COPY adoptions/realm-export.json /opt/keycloak/data/import/realm-export.json

RUN chmod a+x /tmp/*-entrypoint.sh && mkdir -p /data/db

### ini
COPY supervisord/apicurio.ini /etc/supervisor.d/apicurio.ini
COPY supervisord/kafka.ini /etc/supervisor.d/kafka.ini
COPY supervisord/keycloak.ini /etc/supervisor.d/keycloak.ini
COPY supervisord/mongo.ini /etc/supervisor.d/mongo.ini

### Configs
ENV KEYCLOAK_HOSTNAME localhost
ENV BIND localhost
ENV KEYCLOAK_ADMIN admin
ENV KEYCLOAK_ADMIN_PASSWORD admin

# 9092 is kafka
EXPOSE 9092
# keycloak 8080 (http) --> should be mapped to 9090
EXPOSE 8080
# MongoDB
EXPOSE 27017
# Apicurio
EXPOSE 8081

ENTRYPOINT [ "supervisord" ]
CMD ["-n"]
