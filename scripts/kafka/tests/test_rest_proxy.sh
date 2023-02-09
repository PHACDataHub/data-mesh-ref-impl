#!/bin/bash

CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

consumer_name=my_avro_consumer
consumer_instance=my_consumer_instance
rest_proxy_container=rest-proxy
rest_proxy_host=localhost
rest_proxy_port=8082

# Produce a message using Avro embedded data, including the schema which will
# be registered with schema registry and used to validate and serialize
# before storing the data in Kafka
curl -X POST -H "Content-Type: application/vnd.kafka.avro.v2+json" \
    -H "Accept: application/vnd.kafka.v2+json" \
    --data '{"value_schema": "{\"type\": \"record\", \"name\": \"User\", \"fields\": [{\"name\": \"name\", \"type\": \"string\"}]}", "records": [{"value": {"name": "testUser"}}]}' \
    "http://${rest_proxy_host}:${rest_proxy_port}/topics/avrotest"
echo ''

# Expected output from preceding command:
# {"offsets":[{"partition":0,"offset":0,"error_code":null,"error":null}],"key_schema_id":null,"value_schema_id":21}

# Produce a message with Avro key and value.
# Note that if you use Avro values you must also use Avro keys, but the schemas can differ
curl -X POST -H "Content-Type: application/vnd.kafka.avro.v2+json" \
      -H "Accept: application/vnd.kafka.v2+json" \
      --data '{"key_schema": "{\"name\":\"user_id\"  ,\"type\": \"int\"   }", "value_schema": "{\"type\": \"record\", \"name\": \"User\", \"fields\": [{\"name\": \"name\", \"type\": \"string\"}]}", "records": [{"key" : 1 , "value": {"name": "testUser"}}]}' \
      "http://${rest_proxy_host}:${rest_proxy_port}/topics/avrokeytest2"
echo ''

# Expected output from preceding command:
#  {"offsets":[{"partition":0,"offset":0,"error_code":null,"error":null}],"key_schema_id":2,"value_schema_id":1}

# Create a consumer for Avro data, starting at the beginning of the topic's
# log and subscribe to a topic. Then consume some data from a topic, which is decoded, translated to
# JSON, and included in the response. The schema used for deserialization is
# fetched automatically from schema registry. Finally, clean up.
curl -X POST  -H "Content-Type: application/vnd.kafka.v2+json" \
    --data '{"name": "'${consumer_instance}'", "format": "avro", "auto.offset.reset": "earliest"}' \
    http://${rest_proxy_host}:${rest_proxy_port}/consumers/${consumer_name}
echo ''

# Expected output from preceding command:
#  {"instance_id":"my_consumer_instance","base_uri":"http://${rest_proxy_host}:${rest_proxy_port}/consumers/my_avro_consumer/instances/my_consumer_instance"}

curl -X POST -H "Content-Type: application/vnd.kafka.v2+json" --data '{"topics":["avrotest"]}' \
    http://${rest_proxy_host}:${rest_proxy_port}/consumers/${consumer_name}/instances/${consumer_instance}/subscription
# No content in response

curl -X GET -H "Accept: application/vnd.kafka.avro.v2+json" \
      http://${rest_proxy_host}:${rest_proxy_port}/consumers/${consumer_name}/instances/${consumer_instance}/records
echo ''

# Expected output from preceding command:
#  [{"key":null,"value":{"name":"testUser"},"partition":0,"offset":1,"topic":"avrotest"}]

curl -X DELETE -H "Content-Type: application/vnd.kafka.v2+json" \
      http://${rest_proxy_host}:${rest_proxy_port}/consumers/${consumer_name}/instances/${consumer_instance}
# No content in response

echo "Test completed ✅";