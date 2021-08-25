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

## About the image

The image is based on available container images. Namely:

- johnnypark/kafka-zookeeper:2.6.0 (<https://github.com/hey-johnnypark/docker-kafka-zookeeper>)
- jboss/keycloak:13.0.1 (<https://github.com/keycloak/keycloak-containers>)

The license of the used images and their contained programs are untouched.
