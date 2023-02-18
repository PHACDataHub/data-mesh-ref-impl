import configparser
from transformers import pipeline
import pandas as pd

def display(model_outputs):
    df = pd.DataFrame(model_outputs)
    print(df)

config = configparser.ConfigParser()
config.read('/conf/task.ini')

summarizer = pipeline(
    config['pipeline']['name'], 
    model=config['pipeline']['model']
)
outputs = summarizer(
    config['test']['text'], 
    max_length=config.getint('pipeline','max_length'), 
    clean_up_tokenization_spaces=config.getboolean('pipeline','clean_up_tokenization_spaces')
)

print(outputs[0]['summary_text'], '\n')
