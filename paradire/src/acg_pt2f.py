from utils import to_json_str


class Worker(object):
    def __init__(self, config):
        self.config = config
        self.pt = self.config['pt']
        self.access_control = self.config['access_control']
        self.transform_dict = dict()
        for transform_instruction in self.access_control:
            for transform_type, field_list in transform_instruction.items():
                self.transform_dict[transform_type] = [e.strip() for e in field_list.split(',')]

    def start(self):
        print('Worker instance started.', flush=True)

    def process(self, in_topic, msg_key, msg_val):
        request_id = msg_key['request_id']
        
        out_topic = in_topic
        key = msg_key
        val = {k: None if v is None else self.tranform(k, v) for k, v in msg_val.items()}
        val['pt'] = self.pt
        
        return out_topic, key, val

    def tranform(self, field, value):
        if field in self.transform_dict['to_transform']:
            return str(value)[0:4]
        if field in self.transform_dict['to_hash']:
            return str(hash(value))
        if field in self.transform_dict['to_block']:
            return 'XXX'
        
        return value


if __name__ == '__main__':
    from step_config import load_step_config
    from datetime import datetime
    import json
    import sys
    
    yaml_file, workflow_name, step_name = sys.argv[1:4]
    config = load_step_config(yaml_file, workflow_name, step_name)

    worker = Worker(config['worker'])
    worker.start()

    start_time = datetime.now()
    msg_count = 0
    
    topic, msg_key, msg_val = worker.process(
        'test', 
        {'request_id': '1'}, 
        {'request_id': '1', 'patient_id': '123', 'patient_birth_date': '1990-12-12', 'patient_gender': 'F', 'patient_ethnicity': 'Hispanic', 'patient_address': '1 Main Street'}
    )
    msg_count += 1
    print(f"{datetime.now().strftime('%m/%d/%Y, %H:%M:%S')} <<< [#{msg_count}] [{msg_key}] [{msg_val}]", flush=True)
        
    end_time = datetime.now()
    seconds = (end_time - start_time).total_seconds()
    print(f"Total {msg_count} messages. Time spent {seconds} seconds. {msg_count/seconds} messages per seconds.")
