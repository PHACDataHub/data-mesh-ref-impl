import argparse
import re
import os

from bs4 import BeautifulSoup

from confluent_kafka import Consumer
from confluent_kafka.serialization import SerializationContext, MessageField
from confluent_kafka.schema_registry import SchemaRegistryClient
from confluent_kafka.schema_registry.avro import AvroDeserializer


class Rss(object):
    def __init__(self, creator=None, category=None, content=None, description=None, enclosure_url=None, link=None, pub_date=None, title=None):
        self.category = category
        self.content = content
        self.creator = creator
        self.description = description
        self.enclosure_url = enclosure_url
        self.link = link
        self.pub_date = pub_date
        self.title = title


def dict_to_rss(obj, ctx):
    """
    Converts object literal(dict) to an Rss instance.

    Args:
        obj (dict): Object literal(dict)

        ctx (SerializationContext): Metadata pertaining to the serialization
            operation.
    """

    if obj is None:
        return None

    return Rss(
        category=obj['category'],
        content=obj['content'],
        creator=obj['creator'],
        description=obj['description'],
        enclosure_url=obj['enclosure_url'],
        link=obj['link'],
        pub_date=obj['pub_date'],
        title=obj['title']
    )


if __name__ == '__main__':
    topic = 'screenrant-topic'
    schema = "screenrant-rss-value.avsc"

    path = os.path.realpath(os.path.dirname(__file__))
    with open(schema) as f:
        schema_str = f.read()

    sr_conf = {'url': 'http://schema-registry:8081'}
    schema_registry_client = SchemaRegistryClient(sr_conf)

    avro_deserializer = AvroDeserializer(schema_registry_client,
                                         schema_str,
                                         dict_to_rss)

    consumer_conf = {'bootstrap.servers': 'broker:29092',
                     'group.id': 'preprocess-consumer-group',
                     'auto.offset.reset': 'earliest'}

    consumer = Consumer(consumer_conf)
    consumer.subscribe([topic])

    count, rss_count = 0, 0

    while True:
        try:
            # SIGINT can't be handled when polling, limit timeout to 1 second.
            msg = consumer.poll(1.0)
            if msg is None:
                continue

            count += 1
            print("Count #{}".format(count), flush=True)
            rss = avro_deserializer(msg.value(), SerializationContext(msg.topic(), MessageField.VALUE))
            if rss is not None:
                rss_count +=1 
                rss.content = re.sub("\s*\n+\s*$", "", rss.content)
                rss.content = re.sub("^\n+\s+", "", rss.content)
                soup = BeautifulSoup(rss.content)
                links = soup.find_all('a')
                for link in links:
                    print(link, flush=True)
                rss.content = soup.get_text()
                rss.description = re.sub("\s*\n\s*$", "", rss.description)
                rss.description = re.sub("^\n+\s+", "", rss.description)
                rss.title = re.sub("\s*\n\s*$", "", rss.title)
                rss.title = re.sub("^\n+\s+", "", rss.title)
                print("Rss record #{} {}:\n\tcategory: {}\n\tcontent: [{}]\n\tcreator: [{}]\n\tdescription: [{}]\n\tenclosure_url: {}\n\tlink: {}\n\tpub_date: {}\n\ttitle: [{}]\n"
                      .format(rss_count, msg.key(), rss.category, rss.content, rss.creator, rss.description, rss.enclosure_url, rss.link, rss.pub_date, rss.title), flush=True)
            else:
                print("avro_deserializer return None")

        except KeyboardInterrupt:
            break

    consumer.close()
