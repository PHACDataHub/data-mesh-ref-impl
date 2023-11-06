from utils import to_json_str


class Worker(object):
    def __init__(self, config):
        self.config = config
        self.request_identifier = config['request_identifier']
        self.request_converter = config['request_converter']
        self.converter_dict = dict()
        for request_map in self.request_converter:
            for topic, topic_config in request_map.items():
                self.converter_dict[topic] = {'key': topic_config['key'], 'val': topic_config['val'].split(',')}

    def start(self):
        pass
        
    def process(self, msg_key, msg_val):
        request_id = msg_key['request_id']
        request_type = msg_val['request_type']
        
        topic_name = request_type
        key = msg_key
        val = {k: msg_val[k] for k in self.converter_dict[topic_name]['val']}
        
        return topic_name, key, val


if __name__ == '__main__':
    from step_config import load_step_config
    from datetime import datetime
    import json
    import sys
    
    yaml_file, workflow_name, step_name, avro_file = sys.argv[1:5]
    config = load_step_config(yaml_file, workflow_name, step_name)

    worker = Worker(config['worker'])
    worker.start()

    start_time = datetime.now()
    msg_count = 0
    
    print(avro_file, flush=True)
    
    with open(avro_file, 'rt', encoding='utf-8') as in_file:
        lines = in_file.readlines()
        for line in lines:
            key, val = [json.loads(s) for s in line.strip().split('|')]
            topic, msg_key, msg_val = worker.process(key, val)
            msg_count += 1
            print(f"{datetime.now().strftime('%m/%d/%Y, %H:%M:%S')} <<< [#{msg_count}] [{msg_key}] [{msg_val}]", flush=True)
        
    end_time = datetime.now()
    seconds = (end_time - start_time).total_seconds()
    print(f"Total {msg_count} messages. Time spent {seconds} seconds. {msg_count/seconds} messages per seconds.")
