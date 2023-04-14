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


def normalize_rss(key, val):
    rss_val = dict()

    if 'title' in val and val['title']:
        # Trimp whitespaces from beginning and end, removing HTML tags, keep text only
        text = re.sub("\s*\n\s*$", "", val['title'])
        rss_val['title'] = re.sub("^\n+\s+", "", text)
        rss_val['full_text'] = f"{rss_val['title']}. "
    
    if 'category' in val and val['category']:
        # Cleanup HTML text, don't json-stringify it yet
        rss_val['category'] = [BeautifulSoup(e, 'html.parser').get_text() for e in val['category']]
        full_text = rss_val['full_text'] if 'full_text' in rss_val else ''
        rss_val['full_text'] = f"{full_text}{', '.join(rss_val['category'])}. "
        rss_val['category'] = json.dumps(rss_val['category'], cls=NumpyFloatValuesEncoder)
    
    if 'description' in val and val['description']:
        # Trimp whitespaces from beginning and end, removing HTML tags, keep text only
        text = None
        for desc in val['description']:
            if desc:
                desc_str = re.sub("\s*\n\s*$", "", desc)
                desc_str = re.sub("^\n+\s+", "", desc_str)
                text = f"{desc_str}" if text is None else f"{text} {desc_str}"

        if text:
            rss_val['description'] = text
            full_text = rss_val['full_text'] if 'full_text' in rss_val else ''
            rss_val['full_text'] = f"{full_text}{rss_val['description']} "

    if 'content' in val and val['content']:
        # Trimp whitespaces from beginning and end, removing HTML tags, keep text only
        text = re.sub("\s*\n+\s*$", "", val['content'])
        text = re.sub("^\n+\s+", "", text)
        soup = BeautifulSoup(text, 'html.parser')
        rss_val['content'] = soup.get_text()
        full_text = rss_val['full_text'] if 'full_text' in rss_val else ''
        rss_val['full_text'] = f"{full_text}{rss_val['content']}"

        # Create a href_list from links found in content, then json-stringify it
        links = soup.find_all('a')
        rss_val['href_list'] = json.dumps([ {'content': link.get_text(), 'url': link['href'] if 'href' in link and link['href'] else None} for link in links ], cls=NumpyFloatValuesEncoder)

    if 'creator' in val and val['creator']:
        # Cleanup HTML text, and json-stringify it
        rss_val['creator'] = json.dumps([ BeautifulSoup(e, 'html.parser').get_text() for e in val['creator'] ], cls=NumpyFloatValuesEncoder)

    # Keep link as-is
    rss_val['link'] = val['link']

    # Keep pub_date as-is
    rss_val['pub_date'] = val['pub_date']

    # Create the timestamp
    rss_val['timestamp_kp'] = int(time.time())

    # Set message key
    rss_key = { 'link': val['link'], 'pub_date': val['pub_date'] }

    return rss_key, rss_val


def input_processed_rss(msg_key, msg_val):
    return msg_key, msg_val


def output_text_classifier(outputs, msg_key, msg_val):
    result = []
    for i, label in enumerate(outputs['labels']):
        result.append({ 'name': label, 'score': float(outputs['scores'][i]) })

    msg_val['classified_labels'] = json.dumps(result, cls=NumpyFloatValuesEncoder)
    msg_val['timestamp_tc'] = int(time.time())

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
