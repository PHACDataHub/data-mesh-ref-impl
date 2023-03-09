from bs4 import BeautifulSoup
import json
import re
import time

import numpy as np


class NumpyFloatValuesEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, np.float32):
            return float(obj)
        return JSONEncoder.default(self, obj)


def input_rss(key, val):
    rss_val = dict()
    
    rss_val['category'] = [BeautifulSoup(e, 'html.parser').get_text() for e in val['category']]

    rss_val['creator'] = json.dumps(val['creator'], cls=NumpyFloatValuesEncoder)
    rss_val['enclosure_url'] = val['enclosure_url']
    rss_val['link'] = val['link']
    rss_val['pub_date'] = val['pub_date']

    text = re.sub("\s*\n+\s*$", "", val['content'])
    text = re.sub("^\n+\s+", "", text)
    soup = BeautifulSoup(text, 'html.parser')
    rss_val['content'] = soup.get_text()

    links = soup.find_all('a')
    rss_val['href_list'] = json.dumps([ {'content': link.get_text(), 'url': link['href']} for link in links ], cls=NumpyFloatValuesEncoder)

    text = re.sub("\s*\n\s*$", "", val['description'])
    rss_val['description'] = re.sub("^\n+\s+", "", text)

    text = re.sub("\s*\n\s*$", "", val['title'])
    rss_val['title'] = re.sub("^\n+\s+", "", text)

    rss_val['full_text'] = f"{rss_val['title']}. {', '.join(rss_val['category'])}. {rss_val['description']} {rss_val['content']}"

    rss_val['category'] = json.dumps(rss_val['category'], cls=NumpyFloatValuesEncoder)

    rss_val['timestamp_tc'] = int(time.time())

    rss_key = { 'link': val['link'], 'pub_date': val['pub_date'] }

    return rss_key, rss_val


def output_text_classifier(outputs, msg_key, msg_val):
    result = []
    
    for i, label in enumerate(outputs['labels']):
        result.append({ 'name': label, 'score': float(outputs['scores'][i]) })
    msg_val['classified_labels'] = json.dumps(result, cls=NumpyFloatValuesEncoder)
    
    return msg_key, msg_val


def input_text_classifier(msg_key, msg_val):
    return msg_key, msg_val


def output_sentiment_analyzer(outputs, msg_key, msg_val):
    sign = 1.0 if outputs[0]['label'] == 'POSITIVE' else -1.0
    msg_val['sentiment_score'] = sign * float(outputs[0]['score'])
    msg_val['timestamp_sa'] = int(time.time())
    
    return msg_key, msg_val


def output_question_answer(outputs, msg_key, msg_val):
    msg_val['question_answer'] = json.dumps(outputs[0], cls=NumpyFloatValuesEncoder)
    msg_val['timestamp_qa'] = int(time.time())
    
    return msg_key, msg_val


def output_summarizer(outputs, msg_key, msg_val):
    msg_val['summary_text'] = outputs[0]['summary_text']
    msg_val['timestamp_sm'] = int(time.time())
    
    return msg_key, msg_val


def output_named_entity_recognizer(outputs, msg_key, msg_val):
    for e in outputs:
        e['word'] = e['word'].strip()
    msg_val['named_entities'] = json.dumps(outputs, cls=NumpyFloatValuesEncoder)
    msg_val['timestamp_ne'] = int(time.time())
    
    return msg_key, msg_val
