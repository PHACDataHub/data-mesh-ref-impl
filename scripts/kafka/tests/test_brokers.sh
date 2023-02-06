#!/bin/bash

CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

source .env

topic_console=topic-console-test
broker_container_name=broker-1
broker_internal_host=broker-1
broker_internal_port=29092
broker_local_host=localhost
broker_local_port=9092
broker_outside_host=${VM_IP}
broker_outside_port=9003
kafkacat_container=kafkacat

echo "Create ${topic_console} from inside ${broker_container_name} to ${broker_internal_host}:${broker_internal_port} ...";
docker exec -it ${broker_container_name} /bin/kafka-topics \
    --create --topic ${topic_console} \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port};
echo "${topic_console} created ✅";

no_messages=3;
send_file=sent.txt
recv_file=recv.txt
touch ${send_file};
for (( item=1; item<=${no_messages}; item++ ));
do
    echo "key"${item}":value"${item} >> ${send_file};
done
cp ${send_file} vol/broker-1/data/.

echo "Sending ${no_messages} messages into ${topic_console} from ${broker_container_name} to ${broker_internal_host}:${broker_internal_port} ...";
docker exec -it ${broker_container_name} bash -c "cat /var/lib/kafka/data/${send_file} | /bin/kafka-console-producer \
    -bootstrap-server ${broker_internal_host}:${broker_internal_port} \
    --topic ${topic_console}"
echo "${no_messages} messages sent ✅";

echo "Receiving ${no_messages} messages from ${topic_console} ...";
docker exec -it ${broker_container_name} /bin/kafka-console-consumer \
    --topic ${topic_console} --group test-consumer \
    --from-beginning --max-messages ${no_messages} \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} > ${recv_file}
echo "${no_messages} messages received ✅";
sed '$d' ${recv_file} > temp.txt; mv temp.txt ${recv_file}; 
sed 's/\r//g' ${recv_file} > temp.txt; mv temp.txt ${recv_file};
if [ -z "$(diff ${send_file} ${recv_file})" ]; then
    echo 'Test sending/receiving messages completed ✅'
else
    echo 'ERROR: Sent and receive messages did not match.'
    exit 1
fi

echo "Resetting consumer offsets from ${topic_console} ...";
docker exec -it ${broker_container_name} /bin/kafka-consumer-groups \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} \
    --group test-consumer --reset-offsets --to-earliest --all-topics --execute;
echo "Consumer offsets reset ✅";

echo "Receiving ${no_messages} messages from ${topic_console} ...";
docker exec -it ${broker_container_name} /bin/kafka-console-consumer \
    --topic ${topic_console} --group test-consumer \
    --max-messages ${no_messages} \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} > ${recv_file}
echo "${no_messages} messages received ✅";
sed '$d' ${recv_file} > temp.txt; mv temp.txt ${recv_file}; 
sed 's/\r//g' ${recv_file} > temp.txt; mv temp.txt ${recv_file};
if [ -z "$(diff ${send_file} ${recv_file})" ]; then
    echo 'Test sending/receiving messages completed ✅'
else
    echo 'ERROR: Sent and receive messages did not match.'
    exit 1
fi

rm sent.txt recv.txt vol/broker-1/data/${send_file}

echo "Deleting ${topic_console} ...";
docker exec -it ${broker_container_name} /bin/kafka-topics \
    --delete --topic ${topic_console} \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port};
echo ${topic_console} "deleted ✅";
