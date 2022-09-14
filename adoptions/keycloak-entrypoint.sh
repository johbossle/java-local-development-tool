#!/bin/bash
set -eou pipefail

exec /opt/keycloak/bin/kc.sh start-dev --import-realm
exit $?
