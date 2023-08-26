import stanza
from utils import to_json_str


def extract_phrases(tree, key_phrase_dict):
    if len(tree.children) > 0 and all(x.is_preterminal() for x in tree.children):
        words = [x.children[0].label.lower() for x in tree.children]
        text = ' '.join(words)
        if text in key_phrase_dict:
            key_phrase_dict[text][0] += 1
        else:
            key_phrase_dict[text] = [1, words]
        return
    for child in tree.children:
        extract_phrases(child, key_phrase_dict)
            

class Worker(object):

    def __init__(self, config):
        self.config = config
        self.language = config['language']
        self.processors = config['processors']
        self.ner_packages = config['ner_packages'].split(',')
        self.pipeline = None

    def start(self):
        self.pipeline = stanza.Pipeline(lang='en', processors=self.processors, package={"ner": self.ner_packages})
        
    def process(self, msg_key, msg_val):
        if 'cnt' not in msg_val or not msg_val['cnt']:
            return None, None, None
        
        key_phrase_dict = dict()
        named_entity_dict = dict()
        
        print(f">>>>> {msg_key['url']} <<<<<")
        # content = msg_val['cnt'].replace('\n', '\\n')
        # print(f">>>>> {content} <<<<<")
        processed_doc = self.pipeline(msg_val['cnt'])

        for entity in processed_doc.entities:
            text = entity.text.lower()
            if text in named_entity_dict:
                named_entity_dict[text][0] += 1
            else:
                named_entity_dict[text] = [1, entity.type, text.split()]
                
        for k, v in named_entity_dict.items():
            print('NE', k, v)
            
        for sentence in processed_doc.sentences:
            extract_phrases(sentence.constituency, key_phrase_dict)
            
        for k, v in key_phrase_dict.items():
            print('KP', k, v)
        
        return None, msg_key, msg_val


if __name__ == '__main__':
    from datetime import datetime
    import json
    import os
    
    config = {
        'language': 'en',
        'processors': 'tokenize,pos,constituency,ner',
        'ner_packages': 'anatem,bc5cdr,bc4chemd,bionlp13cg,jnlpba,linnaeus,ncbi_disease,s800,i2b2,radiology',
        'do_file': '/data/do-classes.txt',
        'who_file': '/data/who_dons-1-142-kpx.txt',
    }

    worker = Worker(config)
    worker.start()

    start_time = datetime.now()

    messages = []

    count = 0
    with open(config['do_file'], 'rt', encoding='utf-8') as in_file:
        lines = in_file.readlines()
        for line in lines:
            key, val = [json.loads(s) for s in line.strip().split('|')]
            messages.append({'key': key, 'val': val})
            count += 1
        print(f"LOAD [{count}] messages from {config['do_file']}.")

    # count = 0
    # with open(config['who_file'], 'rt', encoding='utf-8') as in_file:
    #     dons = json.load(in_file)
    #     for don in dons:
    #         key, val = {'url': don['url']}, {'url': don['url'], 'cnt': don['cnt']}
    #         messages.append({'key': key, 'val': val})
    #         count += 1
    #         if count == 1:
    #             break
    #     print(f"LOAD [{count}] messages from {config['who_file']}.")
        
    for message in messages:
        msg_key, msg_val = message['key'], message['val']
        topic, msg_key, msg_val = worker.process(msg_key, msg_val)

    end_time = datetime.now()
    seconds = (end_time - start_time).total_seconds()
    print(f"Total {count} messages. Time spent {seconds} seconds. {count//seconds} messages per seconds.")
