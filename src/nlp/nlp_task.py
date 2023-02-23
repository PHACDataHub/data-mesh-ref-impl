import configparser
from transformers import pipeline, GenerationConfig
from tabulate import tabulate
import pandas as pd

from kafka_clients import AvroConsumer, AvroProducer
import wranglers 


ARRAY_LABELS=['candidate_labels']


def get_config(config_file_name):
    config = configparser.ConfigParser()
    config.read(config_file_name)
    return config


def get_kwargs(config, section='pipeline'):
    kwargs = dict()
    if section in config and 'kwargs' in config[section] and config[section]['kwargs']:
        for kwarg_name in config[section]['kwargs'].split(';'):
            if kwarg_name not in ARRAY_LABELS:
                kwargs[kwarg_name] = config[section][kwarg_name]
            else:
                kwargs[kwarg_name] = config[section][kwarg_name].split('|')
    return kwargs


def print_output(model_outputs):
    df = pd.DataFrame(model_outputs)
    prettyprint=tabulate(df, headers='keys', tablefmt='psql')
    print(prettyprint)    


class NLPTask(object):

    def __init__(self, config):
        self.config = config
    
    def create_pipeline(self):
        if self.config['pipeline']['name'] == 'ner':
            pipeline_kwargs = get_kwargs(config)
            self.processor = pipeline(config['pipeline']['name'], model=config['pipeline']['model'], **pipeline_kwargs)
        elif (config['pipeline']['name'] == 'summarization'):
            generation_config = GenerationConfig()
            self.processor = pipeline(config['pipeline']['name'], model=config['pipeline']['model'],  generation_config=generation_config)
        else:
            self.processor = pipeline(config['pipeline']['name'], model=config['pipeline']['model'])

    def process(self, target, display=True):
        processor_kwargs = get_kwargs(self.config, section='processor')
        if (config['pipeline']['name'] == 'question-answering'):
            outputs = [self.processor(context=target, **processor_kwargs)]
        elif (config['pipeline']['name'] == 'zero-shot-classification'):
            outputs = self.processor(target, **processor_kwargs)
        else:
            outputs = self.processor(target)
        
        if display:
            print_output(outputs)
        
        return outputs


if __name__ == '__main__':
    config = get_config('nlp_task.ini')
    
    consumer = AvroConsumer(config['consumer'])
    producer = AvroProducer(config['producer'])

    pre_wrangler = None
    if 'preprocess' in config['wranglers']:
        pre_wrangler = getattr(wranglers, config['wranglers']['preprocess'])
    
    post_wrangler = None
    if 'postprocess' in config['wranglers']:
        post_wrangler = getattr(wranglers, config['wranglers']['postprocess'])

    nlp_task = NLPTask(config)
    nlp_task.create_pipeline()

    consumer.subscribe()
    target = config['producer']['target']
    count = 0

    while True:
        try:
            # SIGINT can't be handled when polling, limit timeout to 1 second.
            msg = consumer.poll(timeout=1.0)
            if msg is None:
                continue

            count += 1
            print("Count #{}".format(count), flush=True)
            msg_key, msg_val = consumer.consume(msg)

            if msg_key is not None or msg_val is not None:
            
                if pre_wrangler:
                    msg_key, msg_val = pre_wrangler(msg_key, msg_val)

                outputs = nlp_task.process(msg_val[target])

                if post_wrangler:
                    msg_key, msg_val = post_wrangler(outputs, msg_key, msg_val)

                producer.produce(msg_key, msg_val)

            else:
                print("Nothing to process.", flush=True)

        except KeyboardInterrupt:
            break

    consumer.close()

