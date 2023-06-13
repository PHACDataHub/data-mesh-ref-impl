from collections import defaultdict

from confluent_kafka import Consumer, Producer
from confluent_kafka.serialization import SerializationContext, MessageField
from confluent_kafka.schema_registry import SchemaRegistryClient
from confluent_kafka.schema_registry.avro import AvroSerializer, AvroDeserializer


def identity_func(obj, ctx):
    return obj


def read_avro_schema(config_section, avro_file):
    with open(config_section[avro_file]) as f:
        avro_schema = f.read()
    return avro_schema


class AvroClient(object):

    def __init__(self, config_section):
        self.poll_time = float(config_section['poll_time'])
        self.schema_registry_client = SchemaRegistryClient({'url': config_section['schema_registry']})
        self.topic_dict = defaultdict(dict)

    def setup_topics(self, config_section, serializer):
        for topic_map in config_section:
            for topic, topic_config in topic_map.items():
                self.topic_dict[topic] = dict()
                self.set_ser_ctx(topic, topic_config, 'avro_key_schema_file', MessageField.KEY, serializer)
                self.set_ser_ctx(topic, topic_config, 'avro_val_schema_file', MessageField.VALUE, serializer)

    def set_ser_ctx(self, topic, topic_config, schema_type, msg_field, serializer):
        if schema_type in topic_config:
            avro_schema = read_avro_schema(topic_config, schema_type)
            self.topic_dict[topic][schema_type] = {
                'ser': serializer(self.schema_registry_client, avro_schema, identity_func),
                'ctx': SerializationContext(topic, msg_field)
            }

    def ser_msg_part(self, msg_part, topic, schema_type):
        if (topic not in self.topic_dict) or (schema_type not in self.topic_dict[topic]):
            return None
        serializer = self.topic_dict[topic][schema_type]['ser']
        context =  self.topic_dict[topic][schema_type]['ctx']
        return serializer(msg_part, context)


class AvroConsumer(AvroClient):

    def __init__(self, config_section):
        super().__init__(config_section)
        self.consumer = Consumer({
            'bootstrap.servers': config_section['bootstrap_servers'],
            'group.id': config_section['consumer_group_id'],
            'auto.offset.reset': config_section['auto_offset_reset'],
            'enable.auto.commit': False
        })
        self.setup_topics(config_section['source_topic'], AvroDeserializer)
        self.topic_names = list(self.topic_dict.keys())

    def subscribe(self):
        self.consumer.subscribe(self.topic_names)

    def poll(self):
        return self.consumer.poll(self.poll_time)

    def consume(self, msg):
        key = self.ser_msg_part(msg.key(), msg.topic(), 'avro_key_schema_file')
        val = self.ser_msg_part(msg.value(), msg.topic(), 'avro_val_schema_file')
        return key, val

    def commit(self):
        self.consumer.commit()

    def close(self):
        self.consumer.close()


class AvroProducer(AvroClient):

    def __init__(self, config_section):
        super().__init__(config_section)
        self.producer = Producer({
            'bootstrap.servers': config_section['bootstrap_servers']
        })
        self.setup_topics(config_section['destination_topic'], AvroSerializer)
        self.topic_names = list(self.topic_dict.keys())

    def produce(self, topic, msg_key, msg_val):
        self.producer.poll(self.poll_time)
        if topic is None and len(self.topic_names) == 1:
            topic = self.topic_names[0]
        if topic in self.topic_names:
            kwargs = { 
                'topic': topic,
                'key': self.ser_msg_part(msg_key, topic, 'avro_key_schema_file'),
                'value': self.ser_msg_part(msg_val, topic, 'avro_val_schema_file')
            }
            self.producer.produce(on_delivery=self.delivery_report, **kwargs)
            self.producer.flush()

    def close(self):
        self.producer.close()

    def delivery_report(self, err, msg):
        if err is not None:
            print("Delivery failed for User record {}: {}".format(msg.key(), err))
            return

        print('User record {} successfully produced to {} [{}] at offset {}'.format(
            msg.key(), msg.topic(), msg.partition(), msg.offset()
        ), flush=True)
