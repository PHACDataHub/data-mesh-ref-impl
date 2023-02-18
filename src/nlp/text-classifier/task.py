import configparser
from transformers import pipeline
import pandas as pd

def display(model_outputs):
    df = pd.DataFrame(model_outputs)
    print(df)

config = configparser.ConfigParser()
config.read('task.ini')

classifier = pipeline(config['pipeline']['name'], model=config['pipeline']['model'])
outputs = classifier(config['test']['text'], candidate_labels=config['pipeline']['candidate_labels'].split(','))

display(outputs)
print('\n')
