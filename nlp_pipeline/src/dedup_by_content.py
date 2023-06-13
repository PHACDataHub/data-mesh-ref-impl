import pickle
from queue import Queue
from threading import Event, Thread

import psycopg2
from sentence_transformers import SentenceTransformer, util
import torch

import utils


SQL_COMMANDS = {
  'load_article_embeddings': """
      SELECT doc_id, para_lengths, pickled, timestamp FROM embeddings ORDER BY timestamp 
  """,
  'insert_article_embeddings': """
      INSERT INTO embeddings(doc_id, para_lengths, pickled, timestamp) VALUES(%s, %s, %s, %s) ON CONFLICT DO NOTHING
  """
}


def find_similar_article(doc_id, input_embeddings, input_lengths, total_input_length, paragraph_similarity_threshold, content_similarty_threshold, batch_of_articles, found_article_event, result_queue):
  for article in batch_of_articles:
    found_article_event.wait(0.1)
    if found_article_event.is_set():
      return

    aid, para_lengths, pickled, _ = article
    article_embeddings = pickle.loads(pickled)
    total_article_length = sum(para_lengths)

    paragraph_pairs_dict = dict()
    cos_sim = util.cos_sim(input_embeddings, article_embeddings)
    for i in range(len(input_embeddings)-1):
      for j in range(len(article_embeddings)-1):
        paragraph_pairs_dict[cos_sim[i][j]] = [i, j]

    # Sort by the highest cosine similarity score
    sorted_paragraph_pairs = []
    for k in sorted(paragraph_pairs_dict.keys(), reverse=True):
      if float(k) < paragraph_similarity_threshold:
        break
      # print(f"{doc_id} {float(k)} {paragraph_pairs_dict[k]}")
      sorted_paragraph_pairs.append([float(k), paragraph_pairs_dict[k]])

    total_cumulative_length, found = 0, False
    for score, pair in sorted_paragraph_pairs:
      i, j = pair
      if total_input_length <= total_article_length:
        total_cumulative_length += input_lengths[i] 
        # print(f"{doc_id} total_cumulative_length={total_cumulative_length/total_input_length} {self.content_similarty_threshold}")
        if total_cumulative_length >= content_similarty_threshold * total_input_length:
          found = True
          break
      else:
        total_cumulative_length += para_lengths[j]
        # print(f"{doc_id} total_cumulative_length={total_cumulative_length/total_article_length} {self.content_similarty_threshold}")
        if total_cumulative_length >= content_similarty_threshold * total_article_length:
          found = True
          break
    
    if found:
      result_queue.put(aid)
      found_article_event.set()
      return


class Worker(object):

  def __init__(self, config):
    self.config = config
    self.device = self.config['gpu_device']
    self.model = SentenceTransformer(self.config['huggingface_model'])
    self.connection = psycopg2.connect(
        user=self.config['postgres']['user'],
        password=self.config['postgres']['pass'],
        host=self.config['postgres']['host'],
        port=self.config['postgres']['port'],
        database=self.config['postgres']['database'])
    self.batch_size = self.config['postgres']['batch_size']
    self.paragraph_similarity_threshold = self.config['paragraph_similarity_threshold']
    self.content_similarty_threshold = self.config['content_similarty_threshold']
    self.number_of_threads = self.config['number_of_threads']

  def __del__(self):
    self.cursor.close()

  def start(self):
    self.cursor = self.connection.cursor()

  def process(self, msg_key, msg_val):
    input_texts, input_lengths = [], []

    if 'headline' in msg_val and msg_val['headline']:
      input_texts.append(msg_val['headline'])
      input_lengths.append(len(msg_val['headline']))
    if 'lead_para' in msg_val and msg_val['lead_para']:
      input_texts.extend([e for e in msg_val['lead_para'] if e])
      input_lengths.extend([len(e) for e in msg_val['lead_para'] if e])
    if 'tail_para' in msg_val and msg_val['tail_para']:
      input_texts.extend([e for e in msg_val['tail_para'] if e])
      input_lengths.extend([len(e) for e in msg_val['tail_para'] if e])

    input_embeddings = self.model.encode(input_texts)
    total_input_length = sum(input_lengths)

    self.cursor.execute(SQL_COMMANDS['load_article_embeddings'])

    while True:
      articles = self.cursor.fetchmany(size=self.batch_size)
      if not articles:
        break

      batch_size = self.batch_size // self.number_of_threads
      work_range = range(0, self.number_of_threads)
      found_article_event, result_queue = Event(), Queue()
      tasks, found_article, aid = [], False, None

      try:
        for i in work_range:
          batch = articles[i*batch_size:(i+1)*batch_size] if i<self.number_of_threads-1 else articles[i*batch_size:]
          if batch:
            task = Thread(
              target=find_similar_article, 
              args=(
                msg_key['doc_id'], input_embeddings, input_lengths, total_input_length, self.paragraph_similarity_threshold, self.content_similarty_threshold, 
                batch, found_article_event, result_queue
              )
            )
            tasks.append(task)
            task.start()

        for i in range(0, len(tasks)):
          tasks[i].join()

        while not result_queue.empty():
          aid = result_queue.get(timeout=1)
          if aid is None:
            break
          found_article = True

      except KeyboardInterrupt:
        found_article_event.set()
    
      if found_article:
        print(f"[SIMILAR] {msg_key['doc_id']} -> {aid}")
        return None, None, None

    self.cursor.execute(
      SQL_COMMANDS['insert_article_embeddings'], 
      (msg_key['doc_id'], input_lengths, pickle.dumps(input_embeddings, protocol=pickle.HIGHEST_PROTOCOL), utils.get_timestamp(),)
    )
    self.connection.commit()
    print(f"[UNKNOWN] {msg_key['doc_id']}")
    return None, msg_key, msg_val


if __name__ == '__main__':
  print('[torch.cuda] IS available' if torch.cuda.is_available() else '[torch.cuda] is NOT available')

  config = {
    'postgres': {
      'host': 'postgres',
      'port': 5432,
      'user': 'postgres',
      'pass': 'phac@2023',
      'database': 'postgres',
      'batch_size': 1000
    },
    'gpu_device': 'cuda',
    'huggingface_model': 'sentence-transformers/all-MiniLM-L6-v2',
    'paragraph_similarity_threshold': 0.85,
    'content_similarty_threshold': 0.85,
    'number_of_threads': 2
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
      'doc_id': 'vi-pc-ABCNEW0020230501ej4u000jj', 
      'headline': "Search for man missing in water along Victorian coast suspended, another man found dead",
      'lead_para': [
          "Emergency services are suspending the search for a man missing since Sunday afternoon in water along Victoria's Great Ocean Road due to deteriorating conditions.",
          "One man has already been found dead in water off Gellibrand Lower, on Victoria's Great Ocean Road."
      ],
      'tail_para': [
        "Victoria, Australia - Emergency Incidents Police annouced later on the day.",
        "Sergeant Danny Brown said authorities were unable to continue their search for the second man due to worsening conditions on the coast.",
        "\"The conditions were far too treacherous again, the swell was up to seven metres and appears to be getting higher again in the next couple of days,\" he said.",
        "Sergeant Brown said the Victoria Police Air Wing would resume searching on Tuesday morning.",
        "Victoria Police said five people went missing in the water around 3pm on Sunday near Otway National Park.",
        "Three people were found stranded on a cliff face between Wreck Beach and Devil's Kitchen around 4:30pm.",
        "They were not injured.",
        "Police said the body of a 30-year-old man from Sunshine North was found on rocks and was retrieved by emergency services.",
        "It is believed the group were abalone fishing in the area, which is not regularly patrolled.",
        "Andrew Devlin, who owns nearby Southern Anchorage Retreat, said it was a dangerous stretch of coastline.",
        "\"It is definitely not a spot to go swimming in. It is really rugged coastline. That's why it gets its name Wreck Beach from all of the shipwrecks that have happened in the area,\" he said.",
        "(c) 2023 Australian Broadcasting Corporation"
      ]
    }, 
    {
    'doc_id': 'vi-pc-INFOB00020230501ej51000c8', 
    'headline': "Películas para ver esta noche en Disney+ Ecuador",
    'lead_para': [
        "Con estas historias, Disney+ busca mantenerse en el gusto de los usuarios",
        "El avance de la tecnología del nuevo milenio, sumado a la pandemia de coronavirus que azotó a nivel internacional, orilló a los ciudadanos a buscar nuevas formas de disfrutar del cine desde la comodidad del hogar."
      ],
    'tail_para': [
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
      'doc_id': 'CBSGA00020230501ej4u0000j', 
      'headline': "Health officials warn irritating symptom may be returning with latest COVID strain",
      'lead_para': [
          "(KTLA) – A new coronavirus subvariant is starting to spread in the U.S. and, according to health experts, it could be causing an annoying symptom to return.",
          "According to the Centers for Disease Control and Prevention, roughly 10% of all COVID cases reported last week were determined to be from the omicron-related XBB.1.16 subvariant, being referred to by some as Arcturus."
      ],
      'tail_para': [
        "After first being reported in January, the World Health Organization declared XBB.1.16 a variant of interest in mid-April, The Hill reports.",
        "The Los Angeles County Department of Public Health is warning residents that this omicron sub-strain of COVID-19 may come with an irritating symptom: conjunctivitis.",
        "Commonly known as pink eye, health officials also reported that pink eye could be linked to COVID early in the pandemic. Then again last year, experts warned there could be a connection between the then-new omicron variant and itchy, irritated eyes.",
        "Now, some health officials are reporting an increase in conjunctivitis cases nationwide.",
        "\"Observational data suggests that people infected with XBB.1.16 may be more likely to experience conjunctivitis as a symptom of their COVID infection, along with more traditional COVID symptoms, such as fever, cough and shortness of breath,\" the LA County Health Department said in a statement. \"Historically, conjunctivitis was reported in 1 to 3% of COVID-19 cases.\"",
        "Conjunctivitis occurs when the lining that covers your eyelid and eyeball, the conjunctiva, becomes inflamed, optometrist Dr. Melanie Dombrowski tells Nexstar's WGHP. Symptoms include eyes becoming pink or red, increased tear production, discharge from the eyes, and itching, irritation, or burning, according to the CDC.",
        "Pink eye is common with respiratory infections like the cold and flu.",
        "However, with the limited data available, the department said it is \"too early to know with certainty\" if XBB.1.16 is truly associated with higher rates of conjunctivitis.",
        "\"Residents should be aware that itchy, watery or red eyes may be a sign of a COVID-19 infection and these symptoms should not be simply dismissed as a result of pollen or seasonal allergies, especially if someone more vulnerable to severe illness could be exposed,\" the Health Department said. \"The fact that we are seeing new strains, with possibly new and different symptoms, tells us that COVID continues to evolve and the way we think about our protections should reflect what we know.\"",
        "You should talk to your doctor if you have pink eye as well as pain in the eyes, sensitivity to light, blurred vision, intense redness, symptoms that aren't improving or get worse, or a weakened immune system, according to the CDC.",
        "Older adults and individuals with underlying health conditions are encouraged to take extra precautions to avoid infection, which includes staying up to date on vaccinations, frequent hand washing, and staying home when feeling sick.",
        "Though officials say Arcturus may be more effective at escaping immune response than other subvariants, it doesn't appear any more severe."
      ]
    }    
  ]
  
  worker = Worker(config)
  worker.start()
  for text in texts:
    _, key, val = worker.process({'doc_id': text['doc_id']}, text)
