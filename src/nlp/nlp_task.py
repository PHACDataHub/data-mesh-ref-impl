import configparser
from transformers import pipeline, GenerationConfig
from tabulate import tabulate
import pandas as pd

def display(model_outputs):
    df = pd.DataFrame(model_outputs)
    prettyprint=tabulate(df, headers='keys', tablefmt='psql')
    print(prettyprint)    

def get_config(config_file_name):
    config = configparser.ConfigParser()
    config.read(config_file_name)
    return config

def get_kwargs(config, section='pipeline'):
    kwargs = dict()
    if section in config and 'kwargs' in config[section] and config[section]['kwargs']:
        for kwarg_name in config[section]['kwargs'].split(';'):
            if kwarg_name != 'candidate_labels':
                kwargs[kwarg_name] = config[section][kwarg_name]
            else:
                kwargs[kwarg_name] = config[section][kwarg_name].split('|')
    return kwargs


config = get_config('nlp_task.ini')

pipeline_kwargs = get_kwargs(config)

if (config['pipeline']['name'] == 'summarization'):
    generation_config = GenerationConfig()
    processor = pipeline(config['pipeline']['name'], model=config['pipeline']['model'],  generation_config=generation_config)
else:
    if pipeline_kwargs:
        processor = pipeline(config['pipeline']['name'], model=config['pipeline']['model'], **pipeline_kwargs)
    else:
        processor = pipeline(config['pipeline']['name'], model=config['pipeline']['model'])

processor_kwargs = get_kwargs(config, section='processor')

if (config['pipeline']['name'] == 'question-answering'):
    outputs = [processor(context=config['test']['text'], **processor_kwargs)]
elif (config['pipeline']['name'] == 'zero-shot-classification'):
    outputs = processor(config['test']['text'], **processor_kwargs)
else:
    outputs = processor(config['test']['text'])

display(outputs)
