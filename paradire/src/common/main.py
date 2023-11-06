from datetime import datetime
import sys
from time import sleep

from kafka_client import AvroConsumer, AvroProducer
from step_config import load_step_config
from worker import Worker


if __name__ == '__main__':
    print(sys.argv)
    if len(sys.argv) < 4:
        print('Usage: python main.py <yaml_file> <workflow_name> <step_name>')
        print('For example: python main.py workflow.yaml main dedup_by_id')
        exit(1)
    
    yaml_file, workflow_name, step_name = sys.argv[1:4]
    config = load_step_config(yaml_file, workflow_name, step_name)

    sleep(30)

    producer = AvroProducer(config['producer'])
    worker = Worker(config['worker'])
    consumer = AvroConsumer(config['consumer'])

    consumer.subscribe()
    worker.start()
    count = 0

    while True:
        try:
            msg = consumer.poll()
            if msg is None:
                continue
            elif msg.error() is not None:
                print(f"--- Error {msg.error()}", flush=True)
                continue

            msg_key, msg_val = consumer.consume(msg)
            if msg_key is None and msg_val is None:
                continue
            print(f"{datetime.now().strftime('%m/%d/%Y, %H:%M:%S')} >>> [#{count}] [{msg_key}]", flush=True)

            count += 1
            mapped_topic, msg_key, msg_val = worker.process(msg.topic(), msg_key, msg_val)
            print(f"{datetime.now().strftime('%m/%d/%Y, %H:%M:%S')} <<< [#{count}] [{msg_key}]", flush=True)

            if msg_key is None and msg_val is None:
                continue

            producer.produce(mapped_topic, msg_key, msg_val)
            consumer.commit()

        except KeyboardInterrupt:
            break

    consumer.close()

