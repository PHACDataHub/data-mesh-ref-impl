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
        self.topic = config_section['topic']
        self.has_key = False
        self.has_val = False

        self.schema_registry_client = SchemaRegistryClient({'url': config_section['schema_registry']})

        if 'avro_key_schema_file' in config_section:
            self.avro_key_schema = read_avro_schema(config_section, 'avro_key_schema_file')
            self.has_key = True

        if 'avro_val_schema_file' in config_section:
            self.avro_val_schema = read_avro_schema(config_section, 'avro_val_schema_file')
            self.has_val = True


class AvroConsumer(AvroClient):

    def __init__(self, config_section):
        super().__init__(config_section)
        self.consumer = Consumer({
            'bootstrap.servers': config_section['bootstrap_servers'],
            'group.id': config_section['consumer_group_id'],
            'auto.offset.reset': config_section['auto_offset_reset']
        })
        if self.has_key:
            self.avro_key_deserializer = AvroDeserializer(self.schema_registry_client, self.avro_key_schema, identity_func)
        if self.has_val:
            self.avro_val_deserializer = AvroDeserializer(self.schema_registry_client, self.avro_val_schema, identity_func)

    def subscribe(self):
        self.consumer.subscribe([self.topic])

    def poll(self, timeout=1.0):
        return self.consumer.poll(timeout)

    def consume(self, msg):
        key, val = None, None

        if self.has_key:
            key = self.avro_key_deserializer(msg.key(), SerializationContext(self.topic, MessageField.KEY))
        if self.has_val:
            val = self.avro_val_deserializer(msg.value(), SerializationContext(self.topic, MessageField.VALUE))

        return key, val

    def close(self):
        self.consumer.close()


class AvroProducer(AvroClient):

    def __init__(self, config_section):
        super().__init__(config_section)
        self.producer = Producer({
            'bootstrap.servers': config_section['bootstrap_servers']
        })
        if self.has_key:
            self.avro_key_serializer = AvroSerializer(self.schema_registry_client, self.avro_key_schema, identity_func)
        if self.has_val:
            self.avro_val_serializer = AvroSerializer(self.schema_registry_client, self.avro_val_schema, identity_func)

    def produce(self, obj_key, obj_val):
        self.producer.poll(0.0)

        kwargs = { 'topic': self.topic }
        if self.has_key:
            kwargs['key'] = self.avro_key_serializer(obj_key, SerializationContext(self.topic, MessageField.KEY))
        if self.has_val:
            kwargs['value'] = self.avro_val_serializer(obj_val, SerializationContext(self.topic, MessageField.VALUE))

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
