# Java Local Development Tool

This is a simple container image to get one container running

- keycloak
- mongodb
- kafka
- apicurio

The running container is intended for easing up local development of java stacks.

## TL;DR;

- clone the project `git clone `
- run the container build command `podman build -t java-ld-tool:latest .`
- start the container `podman run -p 9092:9092 -p 27017:27017 -p8081:8081 -p 9090:8080 --rm java-ld-tool:latest`
- In your service
  - create a file `application-local.yaml`
  - copy over the example configuration (see below)
  - start the service with spring profile local `SPRING_PROFILES_ACTIVE=local`

## Building the container image

```sh
podman build -t java-ld-tool:latest .
```

Attention: Please ensure to use LF as line-ending on Windows machines.

## Starting an ephemeral container

```sh
podman run -p 2181:2181 -p 9092:9092 -p 27017:27017 -p8081:8081 -p 9090:8080 --rm java-ld-tool:latest
```

## Starting a named container

```sh
podman run -p 9092:9092 -p 27017:27017 -p8081:8081 -p 9090:8080 --name java-ld-tool java-ld-tool:latest
```

## The services of this container

- mongodb running at port 27001 without username/password (connection string: `"mongodb://localhost:27017/?"`)
- keycloak oidc provider
  - admin console: <http://localhost:9090> (username: `admin`, password: `admin`)
  - realm `local` with a client called `local-debugging-app`; issuer: `http://localhost:9090/realms/local`
  - user within the realm: username: `admin`, password: `admin`)
- kafka with one broker available at `localhost:9092` (no security)
- apicurio schema-registry `http://localhost:8081` (without authentication)

## Example configuration

```yaml
spring:
  config:
    activate:
      on-profile: local

  data:
    # Mongo DB configuration
    mongodb:
      uri: "mongodb://localhost:27017/?"
      database: "mydatabase"

# Spring Security OAuth2  config
  security:
    oauth2:
      client:
        registration:
          default:
            client-id: "local-debugging-app"
        provider:
          default:
            issuer-uri: "http://localhost:9090/realms/local"

springdoc:
  swagger-ui:
    oauth:
      clientId: "local-debugging-app"

server:
  port: 8080
  ssl:
    enabled: false

feature:
  kafka-events:
    enabled: true
  mongo:
    enabled: true
  security:
    enabled: true
  openapi:
    enabled: true
  webmvc:
    enabled: true

k5.sdk:
  consumer:
    kubernetes:
      namespace: "dev-br"
  oidc:
    clientRegistrationId: "default"
  # Schema Registry configuration
  schema-registry:
    schemaRegistryConfig:
      schemaRegistryUrl: "http://localhost:8081"
      schemaRegistrySecurityEnabled: "false"
  
  springboot: 
    #Component configuration
    deployment.identifier: ""
    server.baseurl: "http://localhost:8080"

    # Topic Binding(s) & Kafka Binding(s) local configurations
    binding.topic:
      topicBindings:
        my-topic-binding-alias:
          topicName: "YourTopicNameHere"
          kafkaBinding: "k5-default-kafka-binding-example"
      kafkaBindings:
        k5-default-kafka-binding-example:
          kafka_brokers_sasl: "localhost:9092"
          user: "u"
          password: "p"
          securityProtocol: "PLAINTEXT"
    #Api Binding from local configuration
#    consumer.api.binding:
#      bindingProperties:
#        binding1:
#          url: <binding-url>
#          k5PropagateSecurityToken: true
#          caCert: ""
#        binding2:
#          url: <binding-url>
#          k5PropagateSecurityToken: true
#          caCert: ""
```

## Tips for dealing with kafka

### Create a topic

within the running container

```sh
/opt/kafka_2.13-3.6.0/bin/kafka-topics.sh --topic trades --create --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1
```

### Send a message

```sh
/opt/kafka_2.13-3.6.0/bin/kafka-console-producer.sh --broker-list localhost:9092 --topic mytopic2 --property parse.key=true --property key.separator=":"
```

## Tips for using this image with windows machines

### Linebreaks

If keycloak is not starting correctly, it might be related to incorrect linebreaks. Please ensure, that you are using LF as line-ending throughout all files in the project. After the checkout sometimes they were re-written to the Windows default.

### Ports

If you have problems connecting from your local machine to any of the provided services (e.g. kafka: 'topic xyz not present in metadata', altough you created it successfully), make sure that Windows is not blocking any of the required ports:

- run `netstat -a -b` in administrator mode
- check if any of the following necessary ports are blocked by windows services
  - 9092 --> kafka
  - 9090 --> keycloak
  - 8081 --> apicurio
  - 27017 --> MongoDB

## About the image

The image is based on available container images. Namely:

- keycloak/keycloak:22.0.5 (<https://github.com/keycloak/keycloak-containers>)
- apicurio/apicurio-registry-mem:2.4.14.Final (<https://github.com/Apicurio/apicurio-registry>)

It also contains mongodb in version 4.0.5 Community from the alpine linux community repository <http://dl-cdn.alpinelinux.org/alpine/v3.9/community> and an installation of apache kafka with KRaft (without zookeeper).

The license of the used images and their contained programs remain untouched.
