#!/bin/bash

source .env

topic=console-test

broker_container_name=broker
broker_internal_host=broker
broker_internal_port=${BROKER_INTERNAL_PORT}

./scripts/create_topic.sh ${topic}

no_messages=3;
send_file=sent.txt
recv_file=recv.txt
consumer_group=console-test-consumer

rm -f ${send_file};
touch ${send_file};

echo "Creating console messages ...";
for (( item=1; item<=${no_messages}; item++ ));
do
    echo "key"${item}":value"${item} >> ${send_file};
done
cp ${send_file} kafka-ce/broker/data/.
cat kafka-ce/broker/data/${send_file}
echo ''

echo "Sending ${no_messages} messages into topic ${topic} from ${broker_container_name} ...";
docker exec -it ${broker_container_name} bash -c \
    "cat /var/lib/kafka/data/${send_file} | /bin/kafka-console-producer --bootstrap-server ${broker_internal_host}:${broker_internal_port} --topic ${topic}"
echo "${no_messages} messages sent ✅";
echo ''

./scripts/get_topic_info.sh ${topic}

echo "Receiving ${no_messages} messages from topic ${topic} ...";
docker exec -it ${broker_container_name} /bin/kafka-console-consumer \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} \
    --topic ${topic} --group ${consumer_group} \
    --from-beginning --max-messages ${no_messages} > ${recv_file}
echo "${no_messages} messages received ✅";
echo ''
cat ${recv_file};
echo ''

sed '$d' ${recv_file} > temp.txt; mv temp.txt ${recv_file}; 
sed 's/\r//g' ${recv_file} > temp.txt; mv temp.txt ${recv_file};
if [ -z "$(diff ${send_file} ${recv_file})" ]; then
    echo 'Test sending/receiving console messages completed ✅'
else
    echo 'ERROR: Sent' ${send_file} 'and receive' ${recv_file} 'messages did not match ❌'
    exit 1
fi
echo ''

./scripts/get_consumer_group_info.sh ${consumer_group}

./scripts/reset_consumer_all_offsets.sh ${consumer_group}

echo "Receiving ${no_messages} messages from topic ${topic} ...";
docker exec -it ${broker_container_name} /bin/kafka-console-consumer \
    --bootstrap-server ${broker_internal_host}:${broker_internal_port} \
    --topic ${topic} --group ${consumer_group} \
    --from-beginning --max-messages ${no_messages} > ${recv_file}
echo "${no_messages} messages received ✅";
echo ''
cat ${recv_file};
echo ''

sed '$d' ${recv_file} > temp.txt; mv temp.txt ${recv_file}; 
sed 's/\r//g' ${recv_file} > temp.txt; mv temp.txt ${recv_file};
if [ -z "$(diff ${send_file} ${recv_file})" ]; then
    echo 'Test sending/receiving console messages completed ✅'
else
    echo 'ERROR: Sent' ${send_file} 'and receive' ${recv_file} 'messages did not match ❌'
    exit 1
fi
echo ''

./scripts/delete_topic.sh ${topic}

rm sent.txt recv.txt kafka-ce/broker/data/${send_file}
