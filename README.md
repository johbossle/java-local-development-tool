# Java Local Development Tool

This is a simple container image to get one container running

- keycloak
- mongodb
- kafka

The running container is intended for easing up local development of java stacks.

## Building the container image

```sh
docker build -t java-ld-tool:latest .
```

Attention: Please ensure to use LF as line-ending on Windows machines.

## Starting an ephemeral container

```sh
docker run -p 2181:2181 -p 9092:9092 -p 27017:27017 -p 9090:8080 --rm java-ld-tool:latest
```

## Starting a named container

```sh
docker run -p 2181:2181 -p 9092:9092 -p 27017:27017 -p 9090:8080 --name java-ld-tool java-ld-tool:latest
```

## The services of this container

- mongodb running at port 27001 without username/password (connection string: `"mongodb://localhost:27017/?"`)
- keycloak oidc provider
  - admin console: <http://localhost:9090> (username: `admin`, password: `admin`)
  - realm `local` with a client called `local-debugging-app`; issuer: `http://localhost:9090/auth/realms/local`
  - user within the realm: username: `admin`, password: `admin`)
- kafka with one broker available at `localhost:9092` (no security)

## Example configuration

```yaml
spring:
  profiles: local

# MongoDB configuration from local configuration file
spring.data.mongodb.uri: "mongodb://localhost:27017/?"

# Topic Binding(s) from local configuration file
de.knowis.cp.binding.topic:
  topicBindings:
    BINDINGNAME:
      topicName: TOPICNAME
      kafkaBinding:
        kafka_brokers_sasl: "localhost:9092"

## alternative 1
#de.knowis.cp.binding.topic:
#  topicBindings:
#    products-events:
#      topicName: "pizza.express.dev.products.events"
#      kafkaBinding: "local"
#    notifications-events:
#      topicName: "pizza.express.dev.notifications.events"
#      kafkaBinding: "local"
#  kafkaBindings:
#    local:
#      kafka_brokers_sasl: "localhost:9092"
#      securityProtocol: "PLAINTEXT"

## alternative 2
#de.knowis.cp:
#  binding.topic:
#    topicBindings:
#      BINDINGNAME:
#        topicName: TOPICNAME
#        kafkaBinding:
#          kafka_brokers_sasl: "localhost:9092"
#          securityProtocol: "PLAINTEXT"
#  consumer.kafka.binding:
#    kafka_brokers_sasl: "localhost:9092"
#    user: "u"
#    password: "p"
#    securityProtocol: "PLAINTEXT"

# Spring Security OAuth2  config
spring.security:
  oauth2:
    client:
      registration:
        default:
          client-id: "local-debugging-app"
      provider:
        default:
          issuer-uri: "http://localhost:9090/auth/realms/local"
```

## Tips for dealing with kafka

### Create a topic

within the running container

```sh
/opt/kafka_2.13-2.6.0/bin 
./kafka-topics.sh --topic trades --create --zookeeper localhost --partitions 1 --replication-factor 1
```

### Send a message

```sh
/opt/kafka_2.13-2.6.0/bin 
./kafka-console-producer.sh --broker-list localhost:9092 --topic trades --property parse.key=true --property key.separator=":"
```

## Tips for using this image with windows machines

### Linebreaks

If keycloak is not starting correctly, it might be related to incorrect linebreaks. Please ensure, that you are using LF as line-ending throughout all files in the project. After the checkout sometimes they were re-written to the Windows default.

### Ports

If you have problems connecting from your local machine to any of the provided services (e.g. kafka: 'topic xyz not present in metadata', altough you created it successfully), make sure that Windows is not blocking any of the required ports:

- run `netstat -a -b` in administrator mode
- check if any of the following necessary ports are blocked by windows services
  - 2181 --> zookeper
  - 9092 --> kafka
  - 8080 --> keycloak
  - 27017 --> MongoDB

## About the image

The image is based on available container images. Namely:

- johnnypark/kafka-zookeeper:2.6.0 (<https://github.com/hey-johnnypark/docker-kafka-zookeeper>)
- jboss/keycloak:13.0.1 (<https://github.com/keycloak/keycloak-containers>)

It also contains mongodb in version 4.0.5 Community from the alpine linux community repository <http://dl-cdn.alpinelinux.org/alpine/v3.9/community>.

The license of the used images and their contained programs remain untouched.
