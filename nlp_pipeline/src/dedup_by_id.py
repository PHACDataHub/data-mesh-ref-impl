import re

from bs4 import BeautifulSoup
import psycopg2

import utils


SQL_COMMANDS = {
    'find_article_id': """
        SELECT doc_id FROM articles WHERE doc_id = ANY(%s)
    """,
    'insert_article_id': """
        INSERT INTO articles(doc_id) VALUES(%s) ON CONFLICT DO NOTHING
    """
}

class Worker(object):

    def __init__(self, config):
        self.config = config
        self.connection = psycopg2.connect(
            user=self.config['postgres']['user'],
            password=self.config['postgres']['pass'],
            host=self.config['postgres']['host'],
            port=self.config['postgres']['port'],
            database=self.config['postgres']['database'])

    def __del__(self):
        self.cursor.close()

    def start(self):
        self.cursor = self.connection.cursor()

    def clean_html_tags(self, msg_val):
        val = { k: v for k, v in msg_val.items() if k in ['folder', 'headline'] }
        for k in ['lead_para', 'tail_para']:
            if k in msg_val and msg_val[k]:
                v = []
                for s in msg_val[k]:
                    if s.startswith('[name: ELink') and s.endswith(']'):
                        continue
                    text = re.sub("\s*\n\s*$", "", s)
                    s = re.sub("^\n+\s+", "", text)
                    v.append(BeautifulSoup(s, 'html.parser').get_text())
                val[k] = v
        return val

    def process(self, msg_key, msg_val):
        # If there is no duplicated id, pass the message
        if ('dup_id_list' not in msg_val) or (not msg_val['dup_id_list']) or (msg_val['dup_id_list'] == ['[]']):
            self.cursor.execute(SQL_COMMANDS['insert_article_id'], (msg_val['doc_id'],))
            self.connection.commit()
            return None, { 'doc_id': msg_val['doc_id'] }, self.clean_html_tags(msg_val)

        # Is the message itself a duplicate?
        self.cursor.execute(SQL_COMMANDS['find_article_id'], (msg_val['dup_id_list'] + [msg_val['doc_id']],))
        found = self.cursor.fetchall()
        if found:
            return None, None, None
        else:
            # Insert the article id and ids of all other duplicates
            self.cursor.executemany(SQL_COMMANDS['insert_article_id'], [(doc_id,) for doc_id in msg_val['dup_id_list'] + [msg_val['doc_id']]])
            self.connection.commit()
            return None, { 'doc_id': msg_val['doc_id'] }, self.clean_html_tags(msg_val)
