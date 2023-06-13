from collections import defaultdict

import stanza
from stanza.models.common.doc import Document
from stanza.pipeline.core import Pipeline
import torch

import utils


class Worker(object):

  def __init__(self, config):
    self.config = config
    self.device = 0 if torch.cuda.is_available() else -1
    self.package = self.config['package']
    self.ner_models = self.config['ner_models'].split(',')
    self.topic_map = dict()
    for topic_map in self.config['destination_topic_map']:
        for topic, ne_list in topic_map.items():
            self.topic_map.update({ ne: topic for ne in ne_list.split(',') })
    self.optional_topic_map = dict()
    for optional_topic_map in self.config['optional_destination_topic_map']:
        for topic, ne_list in optional_topic_map.items():
            self.optional_topic_map.update({ ne: topic for ne in ne_list.split(',') })

  def start(self):
    self.pipeline = stanza.Pipeline('en', package=self.package, processors={'ner': self.ner_models})

  def process(self, msg_key, msg_val):
    found, results = False, dict()
    text = msg_val['headline'] if 'headline' in msg_val and msg_val['headline'] else ''
    text = f"{text}{ ' '.join(msg_val['lead_para']) if 'lead_para' in msg_val and msg_val['lead_para'] else ''}"
    text = f"{text}{ ' '.join(msg_val['tail_para']) if 'tail_para' in msg_val and msg_val['tail_para'] else ''}"
    if text:
      doc = self.pipeline(text)
      ne_dict = defaultdict(list)
      for ent in doc.ents:
        ne_dict[ent.type].append([ent.text, ent.start_char, ent.end_char])

      if ne_dict:
        entity_types = list(set(self.topic_map)) if set(self.topic_map).issubset(set(ne_dict.keys())) else None
        msg_val['bio_ner'] = utils.to_json_str(ne_dict)
        if entity_types:
          topic = self.topic_map[entity_types[0]]
          match_ne_dict = {k: ne_dict[k] for k in entity_types}
          print(f"[FOUND] [{msg_key['doc_id']}] {topic} {match_ne_dict}")
          return 'relevant-articles', msg_key, msg_val

        entity_types = list(set(ne_dict.keys()) & set(self.optional_topic_map))
        if entity_types:
          topic = self.optional_topic_map[entity_types[0]]
          match_ne_dict = {k: ne_dict[k] for k in entity_types}
          print(f"[OPTIONAL] [{msg_key['doc_id']}] {topic} {match_ne_dict}")
          return 'pending-review-articles', msg_key, msg_val
    
    print(f"[IGNORED] [{msg_key['doc_id']}]")
    return 'trashed-articles', msg_key, msg_val


if __name__ == '__main__':
  print('[torch.cuda] IS available' if torch.cuda.is_available() else '[torch.cuda] is NOT available')

  config = {
    'package': 'craft',
    'ner_models': 'AnatEM,BC5CDR,BC4CHEMD,BioNLP13CG,JNLPBA,Linnaeus,NCBI-Disease,S800',
    'destination_topic_map': [ 
      { 'relevant-articles': 'DISEASE' }
    ],
    'optional_destination_topic_map': [
      { 'pending-review-articles': 'AMINO_ACID,ANATOMICAL_SYSTEM,ANATOMY,CANCER,CELL,CELL_LINE,CELL_TYPE,CELLULAR_COMPONENT,CHEMICAL,DISEASE,DEVELOPING_ANATOMICAL_STRUCTURE,DNA,GENE_OR_GENE_PRODUCT,IMMATERIAL_ANATOMICAL_ENTITY,MULTI-TISSUE_STRUCTURE,ORGAN,ORGANISM,ORGANISM_SUBDIVISION,ORGANISM_SUBSTANCE,PATHOLOGICAL_FORMATION,PROBLEM,PROTEIN,RNA,SIMPLE_CHEMICAL,SPECIES,TISSUE' }
    ]
  }

  texts = [
    {
      'doc_id': 'ABCNEW0020230501ej4u000jj', 
      'headline': "Search for man missing in water along Victorian coast suspended, another man found dead",
      'lead_para': [
          "Emergency services are suspending the search for a man missing since Sunday afternoon in water along Victoria's Great Ocean Road due to deteriorating conditions.",
          "One man has already been found dead in water off Gellibrand Lower, on Victoria's Great Ocean Road."
      ],
      'tail_para': [
        "Sergeant Danny Brown said authorities were unable to continue their search for the second man due to worsening conditions on the coast.",
        "\"The conditions were far too treacherous again, the swell was up to seven metres and appears to be getting higher again in the next couple of days,\" he said.",
        "\"We're always optimistic, we are hopeful. Unfortunately the conditions haven't been favourable to anybody.\"",
        "Sergeant Brown said the Victoria Police Air Wing would resume searching on Tuesday morning.",
        "Victoria Police said five people went missing in the water around 3pm on Sunday near Otway National Park.",
        "Three people were found stranded on a cliff face between Wreck Beach and Devil's Kitchen around 4:30pm.",
        "They were not injured.",
        "Police said the body of a 30-year-old man from Sunshine North was found on rocks and was retrieved by emergency services.",
        "It is believed the group were abalone fishing in the area, which is not regularly patrolled.",
        "Andrew Devlin, who owns nearby Southern Anchorage Retreat, said it was a dangerous stretch of coastline.",
        "\"It is definitely not a spot to go swimming in. It is really rugged coastline. That's why it gets its name Wreck Beach from all of the shipwrecks that have happened in the area,\" he said.",
        "\"Some of the swells lately have been quite large and quite dangerous. I do know surfers who aren't prepared to surf the area because it is so dangerous.\""
      ]
    },
    {
      'doc_id': 'FOXKTV0020230501ej4u0000m', 
      'headline': "Health officials warn irritating symptom may be returning with latest COVID strain",
      'lead_para': [
          "(KTLA) - A new coronavirus subvariant is starting to spread in the U.S. and, according to health experts, it could be causing an annoying symptom to return.",
          "According to the Centers for Disease Control and Prevention, roughly 10% of all COVID cases reported last week were determined to be from the omicron-related XBB.1.16 subvariant, being referred to by some as Arcturus."
      ],
      'tail_para': [
        "After first being reported in January, the World Health Organization declared XBB.1.16 a variant of interest in mid-April, The Hill reports.",
        "The Los Angeles County Department of Public Health is warning residents that this omicron sub-strain of COVID-19 may come with an irritating symptom: conjunctivitis.",
        "Commonly known as pink eye, health officials also reported that pink eye could be linked to COVID early in the pandemic. Then again last year, experts warned there could be a connection between the then-new omicron variant and itchy, irritated eyes.",
        "Now, some health officials are reporting an increase in conjunctivitis cases nationwide.",
        "That includes Los Angeles County, where the health department has warned that pink eye may be the newest possible symptom of COVID.",
        "\"Observational data suggests that people infected with XBB.1.16 may be more likely to experience conjunctivitis as a symptom of their COVID infection, along with more traditional COVID symptoms, such as fever, cough and shortness of breath,\" the LA County Health Department said in a statement. \"Historically, conjunctivitis was reported in 1 to 3% of COVID-19 cases.\"",
        "Pink eye is common with respiratory infections like the cold and flu.",
        "However, with the limited data available, the department said it is \"too early to know with certainty\" if XBB.1.16 is truly associated with higher rates of conjunctivitis.",
        "\"Residents should be aware that itchy, watery or red eyes may be a sign of a COVID-19 infection and these symptoms should not be simply dismissed as a result of pollen or seasonal allergies, especially if someone more vulnerable to severe illness could be exposed,\" the Health Department said. \"The fact that we are seeing new strains, with possibly new and different symptoms, tells us that COVID continues to evolve and the way we think about our protections should reflect what we know.\"",
        "You should talk to your doctor if you have pink eye as well as pain in the eyes, sensitivity to light, blurred vision, intense redness, symptoms that aren't improving or get worse, or a weakened immune system, according to the CDC.",
        "Older adults and individuals with underlying health conditions are encouraged to take extra precautions to avoid infection, which includes staying up to date on vaccinations, frequent hand washing, and staying home when feeling sick.",
        "Though officials say Arcturus may be more effective at escaping immune response than other subvariants, it doesn't appear any more severe."
      ]
    },    
    {
      'doc_id': 'KBSWNE0020230501ej510008h', 
      'headline': "5 Additional Mpox Cases Reported as Total Reaches 47",
      'lead_para': [
          "South Korea has confirmed five more cases of mpox as the country's total rises to 47.",
          "According to the Korea Disease Control and Prevention Agency on Monday, three patients are from Seoul, and one each from South Chungcheong Province and Busan, none of whom has traveled overseas within the last three weeks, suggesting local transmissions."
      ],
      'tail_para': [
        "Although the first case of mpox in South Korea reported last June and four more cases through March were all linked with overseas travel, the recent dozens of infections since early April are believed to be infections transmitted in the country.",
        "KDCA chief Jee Young-mee offered assurances that mpox could be sufficiently managed with the current quarantine response capacity and urged those exhibiting symptoms to visit their nearest medical facility for testing."
      ]
    }
  ]
  
  worker = Worker(config)
  for text in texts:
    _, key, val = worker.process(text['doc_id'], text)
    print(val, '\n')
