import configparser
from transformers import pipeline
import pandas as pd

def display(model_outputs):
    df = pd.DataFrame(model_outputs)
    print(df)

config = configparser.ConfigParser()
config.read('task.ini')

reader = pipeline(config['pipeline']['name'], model=config['pipeline']['model'])
output = reader(question=config['pipeline']['question'], context=config['test']['text'])

display([output])
print('\n')
