import stanza
from utils import to_json_str

DOC_PRE='http://purl.obolibrary.org/obo/'
DON_PRE='https://www.who.int/emergencies/disease-outbreak-news/'

URL_MAP = {
    DON_PRE: 'extracted-don-entities',
    DOC_PRE: 'extracted-doc-entities'    
}


def extract_phrases(tree, lemma_dict, key_phrase_dict):
    if len(tree.children) > 0 and all(x.is_preterminal() for x in tree.children):
        words = []
        for x in tree.children:
            if x.label in ['CC', 'DT', 'IN', 'TO']:
                continue
            lemma = lemma_dict[x.children[0].label]
            if lemma:
                words.append(lemma if x.label in  ['NNP', 'NNPS', 'FW'] else lemma.lower())
        if words:
            text = ' '.join(words)
            # print(text)
            if text in key_phrase_dict:
                key_phrase_dict[text][0] += 1
            else:
                key_phrase_dict[text] = [1, words]
            return
    for child in tree.children:
        extract_phrases(child, lemma_dict, key_phrase_dict)
            

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
            print(f"EMPTY CONTENT for [{msg_key}]", flush=True)
            return None, None, None
        
        key_phrase_dict = dict()
        named_entity_dict = dict()
        
        doc = msg_val['cnt'] if not msg_key['url'].startswith(DON_PRE) else msg_val['cnt'].split('\n\n\n\n')[0].strip()
        processed_doc = self.pipeline(doc)

        for entity in processed_doc.entities:
            text = entity.text.lower()
            if text in named_entity_dict:
                named_entity_dict[text][0] += 1
            else:
                named_entity_dict[text] = [1, entity.type, text.split()]

        for sentence in processed_doc.sentences:
            lemma_dict = {word.text: word.lemma for word in sentence.words}
            extract_phrases(sentence.constituency, lemma_dict, key_phrase_dict)

        named_entity_list = []
        for k in sorted(named_entity_dict.keys()):
            v = named_entity_dict[k]
            named_entity_list.append([k, *v])
        
        key_phrase_list = []
        for k in sorted(key_phrase_dict.keys()):
            if k in named_entity_dict:
                continue
            v = key_phrase_dict[k]
            key_phrase_list.append([k, *v])
        
        msg_val['ets'] = to_json_str(named_entity_list)
        msg_val['kps'] = to_json_str(key_phrase_list)

        print(f"[{msg_key['url']}] {len(named_entity_list)} entities, {len(key_phrase_list)} key_phrases", flush=True)
        
        for url_prefix, topic_name in URL_MAP.items():
            if msg_key['url'].startswith(url_prefix):
                return topic_name, msg_key, msg_val


if __name__ == '__main__':
    from datetime import datetime
    import json
    import os
    
    config = {
        'language': 'en',
        'processors': 'tokenize,pos,lemma,constituency,ner',
        'ner_packages': 'anatem,bc5cdr,bc4chemd,bionlp13cg,jnlpba,linnaeus,ncbi_disease,s800,i2b2,radiology',
        'do_file': '/data/do-classes.txt',
        'who_file': '/data/who_dons-1-142-kpx.txt',
    }

    worker = Worker(config)
    worker.start()

    start_time = datetime.now()

    doc_count = 0
    with open(config['do_file'], 'rt', encoding='utf-8') as in_file:
        lines = in_file.readlines()
        for line in lines:
            key, val = [json.loads(s) for s in line.strip().split('|')]
            topic, msg_key, msg_val = worker.process(key, val)
            doc_count += 1
            if doc_count == 20:
                break
            print(f"LOAD [{doc_count}] messages from {config['do_file']}.", flush=True)

    don_count = 0
    with open(config['who_file'], 'rt', encoding='utf-8') as in_file:
        dons = json.load(in_file)
        for don in dons:
            key, val = {'url': don['url']}, {'url': don['url'], 'cnt': don['cnt']}
            topic, msg_key, msg_val = worker.process(key, val)
            don_count += 1
            if don_count == 20:
                break
            print(f"LOAD [{don_count}] messages from {config['who_file']}.", flush=True)
        
    end_time = datetime.now()
    seconds = (end_time - start_time).total_seconds()
    print(f"Total {doc_count + don_count} messages. Time spent {seconds} seconds. {(doc_count + don_count)/seconds} messages per seconds.")
