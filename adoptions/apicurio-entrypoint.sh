#!/bin/bash
set -eou pipefail

cd /apicurio
QUARKUS_HTTP_PORT="8081" JAVA_OPTIONS="-Dquarkus.http.host=0.0.0.0 -Djava.util.logging.manager=org.jboss.logmanager.LogManager" java -jar /apicurio/apicurio-registry-app-2.1.5.Final-runner.jar
exit $?
