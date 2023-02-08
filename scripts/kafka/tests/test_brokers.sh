#!/bin/bash

CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

topic_console=topic-console-test
broker_container_name=broker
broker_internal_host=broker
broker_internal_port=29092

echo "Create ${topic_console} from inside ${broker_container_name} to ${broker_internal_host}:${broker_internal_port} ...";
docker exec -it ${broker_container_name} /bin/kafka-topics \
    --create --topic ${topic_console} \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port};
echo "${topic_console} created ✅";
echo ''

no_messages=3;
send_file=sent.txt
recv_file=recv.txt
touch ${send_file};
for (( item=1; item<=${no_messages}; item++ ));
do
    echo "key"${item}":value"${item} >> ${send_file};
done
cp ${send_file} vol/broker/data/.

echo "Sending ${no_messages} messages into ${topic_console} from ${broker_container_name} ...";
docker exec -it ${broker_container_name} bash -c "cat /var/lib/kafka/data/${send_file} | /bin/kafka-console-producer \
    -bootstrap-server ${broker_internal_host}:${broker_internal_port} \
    --topic ${topic_console}"
echo "${no_messages} messages sent ✅";
echo ''

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
    echo 'ERROR: Sent' ${send_file} 'and receive' ${recv_file} 'messages did not match ❌'
    exit 1
fi
echo ''

echo "Resetting consumer offsets from ${topic_console} ...";
docker exec -it ${broker_container_name} /bin/kafka-consumer-groups \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} \
    --group test-consumer --reset-offsets --to-earliest --all-topics --execute;
echo "Consumer offsets reset ✅";
echo ''

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
    echo 'ERROR: Sent' ${send_file} 'and receive' ${recv_file} 'messages did not match ❌'
    exit 1
fi
echo ''

rm sent.txt recv.txt vol/broker/data/${send_file}

echo "Deleting ${topic_console} ...";
docker exec -it ${broker_container_name} /bin/kafka-topics \
    --delete --topic ${topic_console} \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port};
echo ${topic_console} "deleted ✅";
