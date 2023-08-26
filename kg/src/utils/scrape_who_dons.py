from bs4 import BeautifulSoup
import json
import requests
from time import sleep
import unicodedata


# Note the / at the end
WHO_DON_BASE_URL = 'https://www.who.int/emergencies/disease-outbreak-news/'


class Scraper(object):
    
    def __init__(self, base_url,  start_page, end_page, out_file_name):
        self.base_url = base_url
        self.start_page = start_page
        self.end_page = end_page
        self.out_file_name = out_file_name
        self.session = requests.Session()

    def get_session(self):
        if not self.session:
            self.session = requests.Session()
        return self.session

    def close_session(self):
        self.session.close()
        self.session = None

    def scrape_pages(self):
        self.messages = []
        current_page = self.start_page
        while current_page <= self.end_page:
            self.scrape_page(current_page)
            current_page += 1
            sleep(1)

        with open(f"{self.out_file_name}-{ self.start_page}-{self.end_page}-kpx.txt", "a+t") as out_file:
            json.dump(self.messages, out_file)
            

    def scrape_page(self, current_page):
        while True:
            session = self.get_session()
            print(f"[FETCH] {self.base_url}{current_page}.", flush=True)
            
            try:
                response = session.get(f"{self.base_url}{current_page}")
                print(f"[{response.status_code}] response for {self.base_url}{current_page}.", flush=True)
                
                soup = BeautifulSoup(response.content, 'html.parser')
                href_list = list()
                count = 0
                for link in soup.find_all('a', class_='sf-list-vertical__item'):
                    href_list.append(link['href'])
                    count += 1
                print(f"[{count}] pages are added from {self.base_url}{current_page}.", flush=True)
                break
            
            except Exception as ex:
                print(f"[{ex}] for {self.base_url}{current_page}.", flush=True)
                self.close_session()
                sleep(10)

        with open(f"{self.out_file_name}-{ self.start_page}-{self.end_page}.txt", "a+t") as out_file:
            
            for url in href_list:
                sleep(1)
                while True:
                    session = self.get_session()
                    print(f"[FETCH] {url}.", flush=True)
                    
                    try:
                        response = session.get(url)
                        print(f"[{response.status_code}] response for {url}.", flush=True)
                        
                        page_content = ''
                        soup = BeautifulSoup(response.content, 'html.parser')
                        body = soup.find('article', class_='sf-detail-body-wrapper')
                        for child in body.children:
                            if child.name == 'div' or child.name == 'h3':
                                text = unicodedata.normalize('NFKD', child.get_text()).strip()
                                if child.name == 'div':
                                    page_content = f"{page_content}\n\n{text}" if page_content else f"{text}"
                                else:
                                    page_content = f"{page_content}\n\n\n\n{text}" if page_content else f"{text}"
                        print(f"[{len(page_content)}] content added from {url}.", flush=True)

                        msg_key = {
                            'url': url
                        }
                        msg_val = {
                            'url': url, 
                            'cnt': page_content
                        }
                        out_file.write(f"{json.dumps(msg_key)}|{json.dumps(msg_val)}\n")
                        
                        self.messages.append(msg_val)
                        break
                    
                    except Exception as ex:
                        print(f"[{ex}] for {url}.", flush=True)
                        self.close_session()
                        sleep(10)
                
            self.close_session()



if __name__ == '__main__':
    import sys
    
    if len(sys.argv) < 4:
        print('Usage: python scrape_who_dons.py <output_filename> <start_page> <end_page>')
        print()
        print('Example: python scrape_who_dons.py who_dons 1 10')
        exit(1)
        
    out_file_name = sys.argv[1]
    start_page = int(sys.argv[2])
    end_page = int(sys.argv[3])

    scraper = Scraper(WHO_DON_BASE_URL, start_page, end_page, out_file_name)
    scraper.scrape_pages()
    