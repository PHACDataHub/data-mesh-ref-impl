import configparser

from kafka_clients import AvroConsumer, AvroProducer
import wranglers 


def get_config(config_file_name):
    config = configparser.ConfigParser()
    config.read(config_file_name)
    return config


if __name__ == '__main__':
    config = get_config('kafka-processor.ini')
    
    consumer = AvroConsumer(config['consumer'])
    producer = AvroProducer(config['producer'])

    wrangler = getattr(wranglers, config['wranglers']['process'])
    
    consumer.subscribe()
    count = 0

    while True:
        try:
            # SIGINT can't be handled when polling, limit timeout to 1 second.
            msg = consumer.poll(timeout=1.0)
            if msg is None:
                continue

            count += 1
            print("--> [#{}] [{}] {}".format(count, msg.key(), msg.value()), flush=True)
            msg_key, msg_val = consumer.consume(msg)

            if msg_key is not None or msg_val is not None:
            
                msg_key, msg_val = wrangler(msg_key, msg_val)
                
                print("<-- [#{}] [{}] {}".format(count, msg_key, msg_val), flush=True)
                producer.produce(msg_key, msg_val)

            else:
                print("Nothing to process.", flush=True)

        except KeyboardInterrupt:
            break

    consumer.close()

