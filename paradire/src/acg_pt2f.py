from utils import to_json_str


class Worker(object):
    def __init__(self, config):
        self.config = config
        self.pt = config['pt']

    def start(self):
        pass
        
    def process(self, in_topic, msg_key, msg_val):
        request_id = msg_key['request_id']
        
        topic_name = in_topic
        key = msg_key
        val = {k: msg_val[k] for k in self.converter_dict[topic_name]['val']}
        msg_val['pt'] = self.pt
        
        return in_topic, key, val


if __name__ == '__main__':
    pass