import torch
from transformers import pipeline


LANGUAGE_NAME_MAP = {
  'ar': 'Arabic', 'bg': 'Bulgarian', 'de': 'German', 'el': 'Greek', 'en': 'English', 'es': 'Spanish',
  'fr': 'French', 'hi': 'Hindi', 'it': 'Italian', 'ja': 'Japanese', 'nl': 'Dutch', 'pl': 'Polish',
  'pt': 'Portuguese', 'ru': 'Russian', 'sw': 'Swahili', 'th': 'Thai', 'tr': 'Turkish', 'ur': 'Urdu',
  'vi': 'Vietnamese', 'zh': 'Chinese'
}


class Worker(object):

  def __init__(self, config):
    self.config = config
    self.model_map = {
      lang_id: model_name 
      for model_map in self.config['huggingface_model_map']
      for lang_id, model_name in model_map.items()
    }
    self.device = 0 if torch.cuda.is_available() else -1

  def start(self):
    self.translators = { 'es': pipeline(f"translation_es_to_en", model=self.model_map['es'], device=self.device) }

  def process(self, msg_key, msg_val):
    val = { k: v for k, v in msg_val.items() if k in ['doc_id', 'folder'] }

    lang_id = msg_val['lang_id']
    if lang_id not in self.translators:
      self.translators.update({ lang_id: pipeline(f"translation_{lang_id}_to_en", model=self.model_map[lang_id], device=self.device) })

    translator = self.translators[lang_id]

    val['headline'] = None
    if 'headline' in msg_val and msg_val['headline']:
      outputs = translator(msg_val['headline'], max_length=len(msg_val['headline']))
      # print('headline', outputs)
      val['headline'] = outputs[0]['translation_text']

    val['lead_para'] = None
    if 'lead_para' in msg_val and msg_val['lead_para']:
      outputs = translator(msg_val['lead_para'], max_length=max([len(e) for e in msg_val['lead_para']]))
      # print('lead_para', outputs)
      val['lead_para'] = [e['translation_text'] for e in outputs]

    val['tail_para'] = None
    if 'tail_para' in msg_val and msg_val['tail_para']:
      outputs = translator(msg_val['tail_para'], max_length=max([len(e) for e in msg_val['tail_para']]))
      # print('tail_para', outputs)
      val['tail_para'] = [e['translation_text'] for e in outputs]

    return None, msg_key, val


if __name__ == '__main__':
  print('[torch.cuda] IS available' if torch.cuda.is_available() else '[torch.cuda] is NOT available')

  config = {
    'huggingface_model_map': [
      { 'ar': 'Helsinki-NLP/opus-mt-ar-en' }, { 'bg': 'Helsinki-NLP/opus-mt-bg-en' }, { 'de': 'Helsinki-NLP/opus-mt-de-en' },
      { 'el': 'Helsinki-NLP/opus-mt-tc-big-el-en' }, { 'es': 'Helsinki-NLP/opus-mt-es-en' }, { 'es': 'Helsinki-NLP/opus-mt-es-en' },
      { 'fr': 'Helsinki-NLP/opus-mt-fr-en' }, { 'hi': 'Helsinki-NLP/opus-mt-hi-en' }, { 'it': 'Helsinki-NLP/opus-mt-it-en' },
      { 'ja': 'Helsinki-NLP/opus-mt-ja-en' }, { 'nl': 'Helsinki-NLP/opus-mt-nl-en' }, { 'pl': 'Helsinki-NLP/opus-mt-pl-en' },
      { 'ru': 'Helsinki-NLP/opus-mt-ru-en' }, { 'th': 'Helsinki-NLP/opus-mt-th-en' }, { 'vi': 'Helsinki-NLP/opus-mt-vi-en' },
      { 'zh': 'Helsinki-NLP/opus-mt-zh-en' }
    ]
  }
  texts = [
    { 'lang_id': 'ar', 'headline': "أفلام لمشاهدة الليلة في ديزني + الإكوادور.",
      'lead_para': ["من خلال هذه القصص ، تسعى Disney + إلى البقاء في ذوق المستخدمين"] },
    { 'lang_id': 'bg', 'headline': "Филми за гледане тази вечер в Disney+ Еквадор.",
      'lead_para': ["С тези истории Disney+ се стреми да остане във вкуса на потребителите"] },
    { 'lang_id': 'de', 'headline': "Filme, die Sie heute Abend bei Disney+ Ecuador sehen können." ,
      'lead_para': ["Mit diesen Geschichten möchte Disney+ den Geschmack der Nutzer treffen"] },
    { 'lang_id': 'el', 'headline': "Ταινίες που πρέπει να παρακολουθήσετε απόψε στο Disney+ Ecuador.",
      'lead_para': ["Με αυτές τις ιστορίες, η Disney+ επιδιώκει να παραμείνει στη γεύση των χρηστών"] },
    { 'lang_id': 'es', 'headline': "Películas para ver esta noche en Disney+ Ecuador.",
      'lead_para': ["Con estas historias, Disney+ busca mantenerse en el gusto de los usuarios"] },
    { 'lang_id': 'fr', 'headline': "Films à regarder ce soir à Disney+ Equateur.",
      'lead_para': ["Avec ces histoires, Disney+ cherche à rester dans le goût des utilisateurs"] },
    { 'lang_id': 'hi', 'headline': "डिज़्नी+ इक्वाडोर में आज रात देखने के लिए फ़िल्में।",
      'lead_para': ["इन कहानियों के साथ, डिज़्नी+ उपयोगकर्ताओं की पसंद में बने रहना चाहता है"] },
    { 'lang_id': 'it', 'headline': "Film da guardare stasera su Disney+ Ecuador.",
      'lead_para': ["Con queste storie, Disney+ cerca di rimanere nel gusto degli utenti"] },
    { 'lang_id': 'ja', 'headline': "Disney+ エクアドルで今夜見るべき映画。",
      'lead_para': ["これらのストーリーにより、Disney+ はユーザーの好みに留まることを目指しています"] },
    { 'lang_id': 'nl', 'headline': "Films om vanavond te bekijken bij Disney+ Ecuador.",
      'lead_para': ["Met deze verhalen probeert Disney+ in de smaak te blijven bij de gebruikers"] },
    { 'lang_id': 'pl', 'headline': "Filmy do obejrzenia dziś wieczorem w Disney+ Ecuador.",
      'lead_para': ["Dzięki tym historiom Disney+ stara się pozostać w gustach użytkowników"] },
    { 'lang_id': 'th', 'headline': 'หนังน่าดูคืนนี้ที่ Disney+ เอกวาดอร์',
      'lead_para': ["ด้วยเรื่องราวเหล่านี้ Disney+ พยายามที่จะคงอยู่ในรสนิยมของผู้ใช้"] },
    { 'lang_id': 'vi', 'headline': "Phim để xem tối nay tại Disney + Ecuador.",
      'lead_para': ["Với những câu chuyện này, Disney+ tìm cách tiếp cận thị hiếu của người dùng"] },
    { 'lang_id': 'zh', 'headline': "今晚在 Disney+ 厄瓜多尔观看的电影。",
      'lead_para': ["通过这些故事，Disney+ 力求留在用户的口味中"] },
  ]

  worker = Worker(config)
  for text in texts:
    _, key, val = worker.process(None, text)
    print(text, val)

