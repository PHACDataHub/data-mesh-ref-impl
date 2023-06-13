import torch
from transformers import pipeline

import utils


class Worker(object):

  def __init__(self, config):
    self.config = config
    self.device = 0 if torch.cuda.is_available() else -1
    self.model = self.config['huggingface_model']
    self.labels = self.config['labels'].split(',')
    self.candidates = self.config['candidates'].split(',')
    self.threshold = self.config['threshold']

  def start(self):
    self.topic_filterer = pipeline("zero-shot-classification", model=self.model, device=self.device)

  def process(self, msg_key, msg_val):
    found, results = False, dict()
    text = msg_val['headline'] if 'headline' in msg_val and msg_val['headline'] else ''
    text = f"{text}{ ' '.join(msg_val['lead_para']) if 'lead_para' in msg_val and msg_val['lead_para'] else ''}"
    text = f"{text}{ ' '.join(msg_val['tail_para']) if 'tail_para' in msg_val and msg_val['tail_para'] else ''}"
    if text:
      outputs = self.topic_filterer(text, self.labels, multi_label=True)
      results = { 
        label: float(outputs['scores'][i]) for i, label in enumerate(outputs['labels']) 
        if label in self.candidates and float(outputs['scores'][i]) >= self.threshold
      }
      if results:
        print(f"[FOUND] [{msg_key['doc_id']}] {results}")
        msg_val['labels'] = utils.to_json_str(results)
        return 'filtered-articles', msg_key, msg_val
    
    return 'off-topic-articles', msg_key, msg_val


if __name__ == '__main__':
  print('[torch.cuda] IS available' if torch.cuda.is_available() else '[torch.cuda] is NOT available')

  config = {
    'huggingface_model': 'facebook/bart-large-mnli',
    'labels': 'disaster,disease,health,illness,medical,medicine,outbreak,arts,business,entertainment,environment,fashion,music,politics,science,sports,technology,trade,traffic,war,weather,world',
    'candidates': 'disaster,disease,illness,outbreak,war',
    'threshold': 0.85
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
      'doc_id': 'INFOB00020230501ej51000c8', 
      'headline': "Películas para ver esta noche en Disney+ Ecuador",
      'lead_para': [
          "Con estas historias, Disney+ busca mantenerse en el gusto de los usuarios",
          "El avance de la tecnología del nuevo milenio, sumado a la pandemia de coronavirus que azotó a nivel internacional, orilló a los ciudadanos a buscar nuevas formas de disfrutar del cine desde la comodidad del hogar."
        ],
      'tail_para': [
        "A raíz de ello, han nacido diversas plataformas de streaming, como es el caso de Disney+, que ha logrado sacar provecho con su amplio catálogo de producciones y se ha posicionado en el gusto de los usuarios.",
        "De ese catálogo destacan estas 10 películas, que han ganado fama y se han convertido en el tema de conversación en los últimos días.",
        "Aquí el listado de las más vistas de Disney+ Ecuador:",
        "1. Peter Pan & Wendy",
        "Wendy Darling, una niña que no quiere ir al internado, conoce a Peter Pan, un niño que se niega a crecer. Junto a sus hermanos y a Campanilla, un hada diminuta, viajará con Peter hasta el mágico mundo de Nunca Jamás. Allí conocerá a un malvado pirata, el Capitán Garfio y se embarcará en una apasionante aventura que cambiará su vida para siempre.",
        "2. Red",
        "Mei Lee, una niña de 13 años un poco rara pero segura de sí misma, se debate entre ser la hija obediente que su madre quiere que sea y el caos propio de la adolescencia. Ming, su protectora y ligeramente exigente madre, no se separa nunca de ella lo que es una situación poco deseable para una adolescente. Y por si los cambios en su vida y en su cuerpo no fueran suficientes, cada vez que se emociona demasiado (lo que le ocurre prácticamente todo el tiempo), se convierte en un panda rojo gigante.",
        "3. Vaiana",
        "Una gran aventura acerca de una enérgica adolescente que se embarca en una misión audaz para salvar a su pueblo de una antigua y misteriosa amenaza, en un viaje de autodescubrimiento. La acompañará el arrogante semidiós Maui, quien la guiará en su travesía por el océano en un viaje lleno de acción, plagado de temibles criaturas e imposibles desafíos para restaurar el orden perdido.",
        "4. Coco",
        "Miguel es un joven con el sueño de convertirse en leyenda de la música a pesar de la prohibición de su familia. Su pasión le llevará a adentrarse en la \"Tierra de los Muertos\" para conocer su verdadero legado familiar.",
        "5. Encanto",
        "\"Encanto\" relata la historia de los Madrigal, una familia extraordinaria que vive en una casa mágica de un pueblo vibrante en las montañas de Colombia escondidas en un \"Encanto\". La magia del Encanto ha bendecido a cada niño de la familia con un don único, desde la superfuerza hasta el poder de sanar. A todos, excepto Mirabel, quien desea ser tan especial como el resto de su familia. Pero cuando la magia que rodea al Encanto está en peligro, Mirabel decide que ella, la única Madrigal sin ningún tipo de don único, puede ser la única esperanza de su excepcional familia.",
        "6. Cars",
        "El aspirante a campeón de carreras Rayo McQueen está sobre la vía rápida al éxito, la fama y todo lo que él había soñado, hasta que por error toma un desvío inesperado en la polvorienta y solitaria Ruta 66. Su actitud arrogante se desvanece cuando llega a una pequeña comunidad olvidada que le enseña las cosas importantes de la vida que había olvidado.",
        "7. Luca",
        "Ambientada en un precioso pueblo costero de la Riviera italiana, narra la historia sobre el paso a la edad adulta de un chico que vive un verano inolvidable lleno de helados, pasta e infinitos paseos en scooter. Luca comparte estas aventuras con su nuevo mejor amigo, pero toda la diversión se ve amenazada por un secreto muy profundo: él es un monstruo marino de un mundo que yace bajo la superficie del agua.",
        "8. Ratatouille",
        "Remy es una simpática rata que sueña con convertirse en un gran chef francés a pesar de la oposición de su familia y del problema evidente que supone ser una rata en una profesión que detesta a los roedores. El destino lleva entonces a Remy a las alcantarillas de París, pero su situación no podría ser mejor, ya que se encuentra justo debajo de un restaurante que se ha hecho famoso gracias a Auguste Gusteau, una estrella de la cuisine. A pesar del peligro que representa ser un visitante poco común (y desde luego nada deseado) en los fogones de un exquisito restaurante francés, la pasión de Remy por la cocina pone patas arriba el mundo culinario parisino en una trepidante y emocionante aventura.",
        "9. Frozen 2",
        "¿Por qué nació Elsa con poderes mágicos? La respuesta le está llamando y amenaza su reino. Junto con Anna, Kristoff, Olaf y Sven emprenderá un viaje peligroso e inolvidable. En 'Frozen: El Reino del Hielo', Elsa temía que sus poderes fueran demasiado para el mundo. En 'Frozen 2', deseará que sean suficientes.",
        "10. Guardianes de la galaxia",
        "El temerario aventurero Peter Quill es objeto de un implacable cazarrecompensas después de robar una misteriosa esfera codiciada por Ronan, un poderoso villano cuya ambición amenaza todo el universo. Para poder escapar del incansable Ronan, Quill se ve obligado a pactar una complicada tregua con un cuarteto de disparatados inadaptados: Rocket, un mapache armado con un rifle, Groot, un humanoide con forma de árbol, la letal y enigmática Gamora y el vengativo Drax the Destroyer. Pero cuando Quill descubre el verdadero poder de la esfera, deberá hacer todo lo posible para derrotar a sus extravagantes rivales en un intento desesperado de salvar el destino de la galaxia.",
        "*Algunos títulos pueden repetirse en el ranking debido a que son diferentes episodios o temporadas, asimismo, podrían no traer descripción porque la plataforma no las proporciona.",
        "Disney desbanca a Netflix",
        "Disney+ es una plataforma de streaming que es propiedad de The Walt Disney Company y que ofrece a sus suscriptores un catálogo amplio de películas, series, documentales, entre otros productos multimedia que han sido lanzados bajo los estudios Disney, Pixar, Marvel, Star, National Geographic, entre otros.",
        "El servicio fue lanzado de manera oficial el 12 de noviembre de 2019 en Estados Unidos y Canadá, para posteriormente expandirse a los Países Bajos y España. Fue hasta finales de 2020 que la plataforma finalmente llegó a Latinoamérica y el Caribe, a excepción de Cuba.",
        "De acuerdo con el último corte realizado el 10 de agosto de 2022, el servicio de streaming cuenta con alrededor de 221,1 millones de usuarios a nivel mundial, sobrepasando por primera vez al mayor rival: Netflix, que se ha quedado en 220,67 millones de usuarios.",
        "El total de usuarios que contabiliza Disney+ (152 millones) hace referencia también a su servicio Hulu (46,2 millones) y ESPN (22,8 millones). En contraste, Netflix perdió 200 mil suscriptores en su último balance y se prevé que baje dos millones más.",
        "Sin embargo, su reinado en el mundo del streaming podría no durar mucho debido al anuncio sobre sus nuevos planes de pago, ya que la compañía contempla un nuevo paquete premium por el que se deberá pagar más tras la llegada de una nueva modalidad que contempla publicidad.",
        "Como antecedente, a finales de 2015 Disney lanzó su servicio DisneyLife en Reino Unido, pero a raíz del lanzamiento de Disney+ el servicio fue suspendido",
        "En el momento de su lanzamiento se habló de que la plataforma busca albergar 500 películas y 7.000 episodios de programas o series de televisión; además, se contemplaba el lanzamiento de cuatro películas originales y cinco programas de televisión, lo cual se vio con el lanzamiento de la serie The Mandalorian, que costó cerca de 100 millones de dólares."
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
