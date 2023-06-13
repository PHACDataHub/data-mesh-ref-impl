import torch
from transformers import pipeline


LANGUAGE_NAME_MAP = {
  'ar': 'Arabic', 'bg': 'Bulgarian', 'de': 'German', 'el': 'Greek', 'en': 'English', 'es': 'Spanish',
  'fr': 'French', 'hi': 'Hindi', 'it': 'Italian', 'ja': 'Japanese', 'nl': 'Dutch', 'pl': 'Polish',
  'pt': 'Portuguese', 'ru': 'Russian', 'sw': 'Swahili', 'th': 'Thai', 'tr': 'Turkish', 'ur': 'Urdu',
  'vi': 'Vietnamese', 'zh': 'Chinese',
  'UNKNOWN': 'UNKNOWN'
}


class Worker(object):

  def __init__(self, config):
    self.config = config
    self.default_language = self.config['default_language']
    self.model = self.config['huggingface_model']
    self.topic_map = dict()
    for topic_map in self.config['destination_topic_map']:
        for topic, languages in topic_map.items():
            self.topic_map.update({ language: topic for language in languages.split(',') })

    self.device = 0 if torch.cuda.is_available() else -1

  def start(self):
    self.language_detector = pipeline("text-classification", model=self.model, device=self.device)

  def process(self, msg_key, msg_val):
    outputs = self.language_detector(f"{msg_val['headline']} {msg_val['lead_para'][0]}", truncation=True, max_length=256)
    detected_language = outputs[0]['label'] if (outputs and 'label' in outputs[0]) else self.default_language
    msg_val.update({ 'lang_id': detected_language, 'lang_name': LANGUAGE_NAME_MAP[detected_language] })
    return self.topic_map[detected_language], msg_key, msg_val


if __name__ == '__main__':
  print('[torch.cuda] IS available' if torch.cuda.is_available() else '[torch.cuda] is NOT available')

  config = {
    'huggingface_model': 'papluca/xlm-roberta-base-language-detection',
    'default_language': 'UNKNOWN',
    'destination_topic_map': [ 
      { 'english-articles': 'en' },
      { 'foreign-articles': 'ar,bg,de,el,es,fr,hi,it,ja,nl,pl,pt,ru,sw,th,tr,ur,vi,zh' },
      { 'unknown-language-articles': 'UNKNOWN' }
    ]
  }
  texts = [
    { 'headline': "Movies to watch tonight at Disney+ Ecuador.", 
      'lead_para': ["With these stories, Disney+ seeks to stay in the taste of users"] },
    { 'headline': "أفلام لمشاهدة الليلة في ديزني + الإكوادور.",
      'lead_para': ["من خلال هذه القصص ، تسعى Disney + إلى البقاء في ذوق المستخدمين"] },
    { 'headline': "Филми за гледане тази вечер в Disney+ Еквадор.",
      'lead_para': ["С тези истории Disney+ се стреми да остане във вкуса на потребителите"] },
    { 'headline': "Filme, die Sie heute Abend bei Disney+ Ecuador sehen können." ,
      'lead_para': ["Mit diesen Geschichten möchte Disney+ den Geschmack der Nutzer treffen"] },
    { 'headline': "Ταινίες που πρέπει να παρακολουθήσετε απόψε στο Disney+ Ecuador.",
      'lead_para': ["Με αυτές τις ιστορίες, η Disney+ επιδιώκει να παραμείνει στη γεύση των χρηστών"] },
    { 'headline': "Películas para ver esta noche en Disney+ Ecuador.",
      'lead_para': ["Con estas historias, Disney+ busca mantenerse en el gusto de los usuarios"] },
    { 'headline': "Films à regarder ce soir à Disney+ Equateur.",
      'lead_para': ["Avec ces histoires, Disney+ cherche à rester dans le goût des utilisateurs"] },
    { 'headline': "डिज़्नी+ इक्वाडोर में आज रात देखने के लिए फ़िल्में।",
      'lead_para': ["इन कहानियों के साथ, डिज़्नी+ उपयोगकर्ताओं की पसंद में बने रहना चाहता है"] },
    { 'headline': "Film da guardare stasera su Disney+ Ecuador.",
      'lead_para': ["Con queste storie, Disney+ cerca di rimanere nel gusto degli utenti"] },
    { 'headline': "Disney+ エクアドルで今夜見るべき映画。",
      'lead_para': ["これらのストーリーにより、Disney+ はユーザーの好みに留まることを目指しています"] },
    { 'headline': "Films om vanavond te bekijken bij Disney+ Ecuador.",
      'lead_para': ["Met deze verhalen probeert Disney+ in de smaak te blijven bij de gebruikers"] },
    { 'headline': "Filmes para assistir hoje à noite no Disney+ Equador",
      'lead_para': ["Com essas histórias, Disney+ busca ficar no gosto dos usuários"] },
    { 'headline': "Filamu za kutazama usiku wa leo kwenye Disney+ Ecuador.",
      'lead_para': ["Kwa hadithi hizi, Disney+ inatafuta kusalia katika ladha ya watumiaji"] },
    { 'headline': 'หนังน่าดูคืนนี้ที่ Disney+ เอกวาดอร์',
      'lead_para': ["ด้วยเรื่องราวเหล่านี้ Disney+ พยายามที่จะคงอยู่ในรสนิยมของผู้ใช้"] },
    { 'headline': "Phim để xem tối nay tại Disney + Ecuador.",
      'lead_para': ["Với những câu chuyện này, Disney+ tìm cách tiếp cận thị hiếu của người dùng"] },
    { 'headline': "今晚在 Disney+ 厄瓜多尔观看的电影。",
      'lead_para': ["通过这些故事，Disney+ 力求留在用户的口味中"] },
  ]

  worker = Worker(config)
  for text in texts:
    topic, key, val = worker.process(None, text)
    print(topic, val['detected_language'], text)
