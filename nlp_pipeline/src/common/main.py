import sys

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

    consumer = AvroConsumer(config['consumer'])
    producer = AvroProducer(config['producer'])
    
    worker = Worker(config['worker'])
    
    consumer.subscribe()
    count = 0

    worker.start()
    
    while True:
        try:
            # SIGINT can't be handled when polling, limit timeout to 1 second.
            msg = consumer.poll()
            if msg is None:
                continue
            elif msg.error() is not None:
                print(f"--- Error {msg.error()}", flush=True)
                continue

            count += 1
            # print(f">-- [#{count}] [{ msg.key()}] {msg.value()}", flush=True)

            msg_key, msg_val = consumer.consume(msg)
            print(f"->- [#{count}] [{msg_key}] {msg_val}", flush=True)

            if msg_key is not None or msg_val is not None:
                mapped_topic, msg_key, msg_val = worker.process(msg_key, msg_val)
                print(f"--> [#{count}] [{mapped_topic}] [{msg_key}] {msg_val}", flush=True)

                if msg_key is not None or msg_val is not None:                
                    producer.produce(mapped_topic, msg_key, msg_val)

            else:
                print(f"--- [#{count}] Nothing to process.", flush=True)
            
            consumer.commit()

        except KeyboardInterrupt:
            break

    consumer.close()

