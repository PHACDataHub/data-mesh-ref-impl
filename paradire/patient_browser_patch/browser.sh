#!/bin/sh

# Update the FHIR server URL if the PT is set.
if [[ ! -z "$PT" ]]; then
echo "replacing to $PT"
    sed -i "s/http:\/\/localhost:8080\/fhir/https:\/\/fhir.$PT.paradire.phac-aspc.alpha.canada.ca\/fhir/" /usr/share/nginx/html/config/default.json5
fi

nginx -g 'daemon off;'
