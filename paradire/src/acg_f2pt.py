from utils import to_json_str


class Worker(object):
    def __init__(self, config):
        self.config = config
        self.pt = self.config['pt']
        self.pt_selector = self.config['pt_selector']
        self.converter_dict = dict()
        for request_map in self.config['request_converter']:
            for topic, topic_config in request_map.items():
                self.converter_dict[topic] = { 
                    'key': topic_config['key'],
                    'val': [e.strip() for e in topic_config['val'].split(',')]
                }

    def start(self):
        print('Worker instance started.', flush=True)
        
    def process(self, in_topic, msg_key, msg_val):
        request_id = msg_key['request_id']
        
        if self.pt not in msg_val[self.pt_selector].split(','):
            print(f"{self.pt} is NOT in {msg_val[self.pt_selector]}")
            return None, None, None

        out_topic = in_topic
        key = msg_key
        val = {k: msg_val[k] for k in self.converter_dict[out_topic]['val']}
        
        val[self.pt_selector] = self.pt

        return out_topic, key, val


if __name__ == '__main__':
    from step_config import load_step_config
    from datetime import datetime
    import json
    import os
    import sys
    
    yaml_file, workflow_name, step_name, avro_dir = sys.argv[1:5]
    config = load_step_config(yaml_file, workflow_name, step_name)

    worker = Worker(config['worker'])
    worker.start()

    start_time = datetime.now()
    msg_count = 0
    
    for file in os.listdir(avro_dir):
        avro_file = os.path.join(avro_dir, file)
        if not os.path.isfile(avro_file) or not avro_file.endswith('.avro'):
            continue
        
        with open(avro_file, 'rt', encoding='utf-8') as in_file:
            lines = in_file.readlines()
            for line in lines:
                key, val = [json.loads(s) for s in line.strip().split('|')]
                topic = val['request_id'][:val['request_id'].rfind('-')]
                topic, msg_key, msg_val = worker.process(topic, key, val)
                msg_count += 1
                print(f"{datetime.now().strftime('%m/%d/%Y, %H:%M:%S')} <<< [#{msg_count}] [{msg_key}] [{msg_val}]", flush=True)
        
    end_time = datetime.now()
    seconds = (end_time - start_time).total_seconds()
    print(f"Total {msg_count} messages. Time spent {seconds} seconds. {msg_count/seconds} messages per seconds.")
