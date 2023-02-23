## Movie Recommendation

Brief Description:
- the integration of NLP containers (per task as shown), with pre-trained datasets, and datasets for fine-tuning,
- some sort of descriptive configuration (in Confluent Cloud there is a Stream Designer, which is very convenient for orchestrating the workflow pipeline mesh),
- some additional movie info databases (from sources highlighted in the diagram), perhaps some cloud storage for large binary data (to avoid long download time, shorten setup time)
- some harvesters to collect movie news (from sources highlighted in the diagram)
- the one that will probably takes large portion of time is to construct a UI which capable to issue formal and “natural language” queries, based on React, communicating via GraphQL, and capable of doing some good visualizations.

**The example**

Excerpt from this news [First 'Joker: Folie à Deux' Image of Lady Gaga's Harley Quinn](https://collider.com/joker-2-image-lady-gaga-joaquin-phoenix/):
```
Who says Valentine's Day can't have some jokes?
Director Todd Phillips took to Instagram to unveil the first look at Lady Gaga in the sequel Joker: Folie à Deux.
While her role is currently under wraps, all signs appear to point to the multi-hyphenate portraying iconic DC character Harley Quinn.
The Joker sequel is set to release on October 4, 2024.
Gaga isn't alone in the image, which sees the return of Joaquin Phoenix's Arthur Fleck/Joker.
He's complete in marred clown makeup and clearly happy to be in the embrace of her character.
Plot details are not known at the moment.
However, this image appears to correlate with Harley Quinn's origin as Joker's psychiatrist in Arkham Asylum, the presumed location for the sequel.
The ending of Joker found Arthur having his way in the famed Gotham facility.
```

Below a few so-called `Natural Language Processing Tasks` (in short `NLP tasks`) are shown.

*Task 1 - Summarize the news in a few sentences*

```bash
Todd Phillips took to Instagram to unveil the first look at Lady Gaga in the sequel Joker: Folie à Deux. All signs appear to point to the multi-hyphenate portraying iconic DC character Harley Quinn. The Joker sequel is set to release on October 4, 2024.
```

*Task 2 - What is the news about: education, politics, business, health, sport, or movie?*

```bash
                                            sequence     labels    scores
0  Who says Valentine's Day can't have some jokes...      movie  0.551902
1  Who says Valentine's Day can't have some jokes...      sport  0.205439
2  Who says Valentine's Day can't have some jokes...   business  0.103893
3  Who says Valentine's Day can't have some jokes...     health  0.084764
4  Who says Valentine's Day can't have some jokes...  education  0.027428
5  Who says Valentine's Day can't have some jokes...   politics  0.026575
```

*Task 3 - What named entities (people, date, organization, location, etc) mentioned in the news?*

```bash
   entity_group     score                  word  start  end
0          MISC  0.996852     Valentine ' s Day      9   24
1           PER  0.999712         Todd Phillips     57   70
2          MISC  0.594972                 Insta     79   84
3           PER  0.998348             Lady Gaga    117  126
4          MISC  0.986863  Joker : Folie à Deux    141  160
5           ORG  0.971730                    DC    270  272
6           PER  0.995922          Harley Quinn    283  295
7          MISC  0.983769                 Joker    301  306
8           PER  0.999261                  Gaga    352  356
9           PER  0.999269       Joaquin Phoenix    408  423
10          PER  0.970964          Arthur Fleck    426  438
11          PER  0.996184                 Joker    439  444
12          PER  0.998973          Harley Quinn    628  640
13          PER  0.991769                 Joker    653  658
14          LOC  0.992751         Arkham Asylum    677  690
15         MISC  0.767194                 Joker    744  749
16          PER  0.999083                Arthur    756  762
17          LOC  0.997191                Gotham    791  797
```

*Task 4 - Answering the question "What movie is in the news?"*

```bash
score  start  end               answer
0  0.938275    141  160  Joker: Folie à Deux
```

*Task 5 - Answering the question "Who is the director of the movie?"*
```bash
      score  start  end         answer
0  0.984972     57   70  Todd Phillips
```

*Task 6 - Answering the question "Who plays the main villain of the movie?"*

```bash
      score  start  end        answer
0  0.334782    283  295  Harley Quinn
```

The beauty of it is that *all these tasks are plug-and-play* and *they can scale very well* because there is no limitation on the number of instances on the cloud. Obviously a good knowledge base needs to be built for movie, actor, etc but those are available at IMDb, etc. 

`Kafka Cluster` will be used as *the underlaying streaming architecture* to exchange messages between these tasks. So each of the `NLP tasks` can work independently, producing/consuming messages into/out-of Kafka topics.

&nbsp;

### A. Natural Language Processing Tasks

**Credit [NLP PLanet](https://www.nlplanet.org)**

<details>
<summary>Click here for more details.</summary>
<p>

1. Text Preprocessing
  + Coreference Resolution: clustering mentions in text that refer to the same underlying real-world entities.
  + Part Of Speech (POS) tagging: tagging a word in a text with its part of speech. A part of speech is a category of words with similar grammatical properties, such as noun, verb, adjective, adverb, pronoun, preposition, conjunction, etc.
  + Word Sense Disambiguation: associating words in context with their most suitable entry in a pre-defined sense inventory (typically WordNet).
  + Grammatical Error Correction: correcting different kinds of errors in text such as spelling, punctuation, grammatical, and word choice errors.
  + Feature Extraction: extraction of generic numerical features from text, usually embeddings.
2. Classification
  + Text Classification: assigning a category to a sentence or document (e.g. spam filtering).
  + Sentiment Analysis: identifying the polarity of a piece of text.
3. Information Retrieval and Document Ranking
  + Sentence/document similarity: determining how similar two texts are.
  + Question Answering: the task of answering a question in natural language.
4. Text-to-Text Generation
  + Machine Translation: translating from one language to another.
  + Text Generation: creating text that appears indistinguishable from human-written text.
  + Text Summarization: creating a shortened version of several documents that preserves most of their meaning.
  + Text Simplification: making a text easier to read and understand, while preserving its main ideas and approximate meaning.
  + Lexical Normalization: translating/transforming a non-standard text to a standard register.
  + Paraphrase Generation: creating an output sentence that preserves the meaning of input but includes variations in word choice and grammar.
5. Knowledge bases, entities and relations
  + Relation extraction: extracting semantic relationships from a text. Extracted relationships usually occur between two or more entities and fall into specific semantic categories (e.g. lives in, sister of, etc).
  + Relation prediction: identifying a named relation between two named semantic entities.
  + Named Entity Recognition: tagging entities in text with their corresponding type, typically in BIO notation.
  + Entity Linking: recognizing and disambiguating named entities to a knowledge base (typically Wikidata).
6. Topics and Keywords
  + Topic Modeling: identifying abstract “topics” underlying a collection of documents.
  + Keyword Extraction: identifying the most relevant terms to describe the subject of a document
7. Chatbots
  + Intent Detection: capturing the semantics behind messages from users and assigning them to the correct label.
  + Slot Filling: aims to extract the values of certain types of attributes (or slots, such as cities or dates) for a given entity from texts.
  + Dialog Management: managing of state and flow of conversations.
8. Text Reasoning
  + Common Sense Reasoning: use of “common sense” or world knowledge to make inferences.
  + Natural Language Inference: determining whether a “hypothesis” is true (entailment), false (contradiction), or undetermined (neutral) given a “premise”.
9. Fake News and Hate Speech Detection
  + Fake News Detection: detecting and filtering out texts containing false and misleading information.
  + Stance Detection: determining an individual’s reaction to a primary actor’s claim. It is a core part of a set of approaches to fake news assessment.
  + Hate Speech Detection: detecting if a piece of text contains hate speech.
10. Text-to-Data and viceversa
  + Text-to-Speech: technology that reads digital text aloud.
  + Speech-to-Text: transcribing speech to text.
  + Text-to-Image: generating photo-realistic images which are semantically consistent with the text descriptions.
  + Data-to-Text: producing text from non-linguistic input, such as databases of records, spreadsheets, and expert system knowledge bases.

![NLP Task](../img/movie-rec/NLP_tasks.png)

</p>
</details>

### B. Architecture Overview

![Architecture Overview](../img/movie-rec/DMRI-EXC3-Movie-Recommendation.001.png)

### C. Iterations

#### [C.1. Iteration 1](#c1-iteration-1)

In this iteration, we aim to accomplish the following:
1. **Task 1** - Creation of a `Pipelayer` [ReactFlow](https://reactflow.dev)-based tool that allow
  + visual design of the data streams between the components of the `Kafka Cluster` and the `NLP Cluster`.
  + providing configuration files for the components in order to connect to `Kafka` data streaming infrastructure as well as to customize the generic `NLP task`.
  + keep the whole visual design and its configuration parameters in a `json` file for later purposes such as easy reloading, management, and monitoring.
2. **Task 2** -  Creation of multiple generic `NLP tasks`, packaged as `Docker` images, equipped with `Python`-based `Kafka` consumers and providers, and easy to be customized by configuration provided by the `Pipelayer`.
3. **Task 3** - Data integration 
  + Integration of an instance of `FilePulse Source Connector` for `XML files` that enables capture of daily news from  [`ScreenRant`](https://screenrant.com)
  + Integration of another instance of `FilePulse Source Connector` for `TSV files` that enables to import the [`IMDb dataset`](https://www.imdb.com/interfaces/).
4. **Task 4**: Graph database for movie data, tracking lineage, and data visualization
  - Setup a `Neo4j` instance to accepts movie news processing status and information.
  - Setup a `Neodash` instance to display `top recent movie recommendation` and `movie data lineage` (processing result throughout our data streams)
5. **Task 5**: Showcasing
  - Allow access to `Neodash` dashboards for all users
  - Allow access to `Pipelayer`, `Neo4j` only at local machine.

![Iteration 1](../img/movie-rec/DMRI-Example-Case-3-Movie-Recommendation-Iteration-1.png)

What will not be included in this iteration:
- Personalization, the site will be public for all user and no personalized feature.
- No scaling for multiple `Kafka brokers` or `NLP tasks`.
- No customization for `NLP pipelines` or `Recommendation dashboard`.

&nbsp;

---

**Task 2** `NLP` task as `Docker` image

*Task 2: Part 1:* Installing `NVIDIA driver`, `NVIDIA Container Toolkit`, and `Pytorch` docker.

**Credit** [Develop like a Pro with NVIDIA + Docker + VS Code + PyTorch](https://blog.roboflow.com/nvidia-docker-vscode-pytorch/)

The `NVIDIA Container Toolkit` allows users to build and run GPU accelerated containers. The toolkit includes a container runtime library and utilities to automatically configure containers to leverage `NVIDIA` GPUs.

![`NVIDIA Container Toolkit`](../img/movie-rec/nvidia-container-toolkit.png)

We need to install:
- the proper `NVIDIA Driver` for the GPUs coming with the virtual machine (unless they are provided by a serverless enviroment)
- `Nvidia Docker` for GPU-Accelerated Containers
- `PyTorch Docker` supported by the `NVIDIA Container Toolkit` and then test the docker by running `MNIST algorithm`


<details>
<summary>Click here for more details.</summary>
<p>

1. A virtual machine is created in the `Google Cloud Platform`:

- `n1-standard-8`, 8 vCPU, 30GB RAM, `threads-per-core=2`, `visible-core-count=4`
- `NVIDIA T4`
- `ubuntu-2204-jammy-v20230114`
- 100 GB persistent disk
- access via SSH (keys)
- allow HTTP/HTTPS (with provisioned static internal/external IPs)

2. Install Docker and test the installation:

```bash
./scripts/docker/install.sh
./scripts/docker/test.sh
```

3. Install `gcc`, `make`

```bash
sudo apt install gcc make
```

4. Download driver for `NVIDIA Tesla T4` supporting `CUDA 11.7`

```bash
wget "https://us.download.nvidia.com/tesla/515.86.01/NVIDIA-Linux-x86_64-515.86.01.run"
chmod +x NVIDIA-Linux-x86_64-515.86.01.run
sudo ./NVIDIA-Linux-x86_64-515.86.01.run
```

5. Run `nvidia-smi` to verify installation
```bash
nvidia-smi
```
```bash
Fri Feb 17 20:21:13 2023       
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 515.86.01    Driver Version: 515.86.01    CUDA Version: 11.7     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|                               |                      |               MIG M. |
|===============================+======================+======================|
|   0  Tesla T4            Off  | 00000000:00:04.0 Off |                    0 |
| N/A   38C    P0    28W /  70W |      2MiB / 15360MiB |      4%      Default |
|                               |                      |                  N/A |
+-------------------------------+----------------------+----------------------+
                                                                               
+-----------------------------------------------------------------------------+
| Processes:                                                                  |
|  GPU   GI   CI        PID   Type   Process name                  GPU Memory |
|        ID   ID                                                   Usage      |
|=============================================================================|
|  No running processes found                                                 |
+-----------------------------------------------------------------------------+
```

6. Install Nvidia Docker for GPU-Accelerated Containers

```bash
distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
  && curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update
sudo apt-get install -y nvidia-docker2
sudo systemctl restart docker
```

7. Test the installation. You should see the correct output *from* `nvidia-smi` *inside the container*. 

```bash
docker run --rm --gpus all nvidia/cuda:11.7.1-base-ubuntu22.04 nvidia-smi
```
```bash
Fri Feb 17 20:23:57 2023       
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 515.86.01    Driver Version: 515.86.01    CUDA Version: 11.7     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|                               |                      |               MIG M. |
|===============================+======================+======================|
|   0  Tesla T4            Off  | 00000000:00:04.0 Off |                    0 |
| N/A   40C    P0    28W /  70W |      2MiB / 15360MiB |      5%      Default |
|                               |                      |                  N/A |
+-------------------------------+----------------------+----------------------+
                                                                               
+-----------------------------------------------------------------------------+
| Processes:                                                                  |
|  GPU   GI   CI        PID   Type   Process name                  GPU Memory |
|        ID   ID                                                   Usage      |
|=============================================================================|
|  No running processes found                                                 |
+-----------------------------------------------------------------------------+
```

`--gpus` is used to specify which GPU the container should see, all means "all of them". If you want to expose only one you can pass its id `--gpus 1`. You can also specify a list of GPUs to use, `--gpus "device=1,2"`

8. Run GPU Accelerated Containers with PyTorch

```bash
docker run --gpus all -it --rm nvcr.io/nvidia/pytorch:23.01-py3
```

9. Changing to higher performance command line options

```bash
docker run --gpus all --ipc=host --ulimit memlock=-1 --ulimit stack=67108864 -it --rm nvcr.io/nvidia/pytorch:23.01-py3
```

```bash
=============
== PyTorch ==
=============

NVIDIA Release 23.01 (build 52269074)
PyTorch Version 1.14.0a0+44dac51

Container image Copyright (c) 2023, NVIDIA CORPORATION & AFFILIATES. All rights reserved.

Copyright (c) 2014-2023 Facebook Inc.
Copyright (c) 2011-2014 Idiap Research Institute (Ronan Collobert)
Copyright (c) 2012-2014 Deepmind Technologies    (Koray Kavukcuoglu)
Copyright (c) 2011-2012 NEC Laboratories America (Koray Kavukcuoglu)
Copyright (c) 2011-2013 NYU                      (Clement Farabet)
Copyright (c) 2006-2010 NEC Laboratories America (Ronan Collobert, Leon Bottou, Iain Melvin, Jason Weston)
Copyright (c) 2006      Idiap Research Institute (Samy Bengio)
Copyright (c) 2001-2004 Idiap Research Institute (Ronan Collobert, Samy Bengio, Johnny Mariethoz)
Copyright (c) 2015      Google Inc.
Copyright (c) 2015      Yangqing Jia
Copyright (c) 2013-2016 The Caffe contributors
All rights reserved.

Various files include modifications (c) NVIDIA CORPORATION & AFFILIATES.  All rights reserved.

This container image and its contents are governed by the NVIDIA Deep Learning Container License.
By pulling and using the container, you accept the terms and conditions of this license:
https://developer.nvidia.com/ngc/nvidia-deep-learning-container-license

NOTE: CUDA Forward Compatibility mode ENABLED.
  Using CUDA 12.0 driver version 525.85.11 with kernel driver version 515.86.01.
  See https://docs.nvidia.com/deploy/cuda-compatibility/ for details.

root@6e7bbf2efd04:/workspace# python
Python 3.8.10 (default, Nov 14 2022, 12:59:47) 
[GCC 9.4.0] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>> import torch
>>> torch.cuda.is_available()
True
>>> torch.backends.cudnn.version()
8700
>>> 
```

10. Now we can proceed to test [`MNIST Handwritten Digit Recognition in PyTorch`](../src/movie-rec/train.py)

```bash
./scripts/nlp/test.sh
```

```bash
Downloading http://yann.lecun.com/exdb/mnist/train-images-idx3-ubyte.gz
Downloading http://yann.lecun.com/exdb/mnist/train-images-idx3-ubyte.gz to ../data/MNIST/raw/train-images-idx3-ubyte.gz
100%|██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████| 9912422/9912422 [00:00<00:00, 42952511.03it/s]
Extracting ../data/MNIST/raw/train-images-idx3-ubyte.gz to ../data/MNIST/raw

Downloading http://yann.lecun.com/exdb/mnist/train-labels-idx1-ubyte.gz
Downloading http://yann.lecun.com/exdb/mnist/train-labels-idx1-ubyte.gz to ../data/MNIST/raw/train-labels-idx1-ubyte.gz
100%|██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████| 28881/28881 [00:00<00:00, 15283332.55it/s]
Extracting ../data/MNIST/raw/train-labels-idx1-ubyte.gz to ../data/MNIST/raw

Downloading http://yann.lecun.com/exdb/mnist/t10k-images-idx3-ubyte.gz
Downloading http://yann.lecun.com/exdb/mnist/t10k-images-idx3-ubyte.gz to ../data/MNIST/raw/t10k-images-idx3-ubyte.gz
100%|██████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████| 1648877/1648877 [00:00<00:00, 10997068.46it/s]
Extracting ../data/MNIST/raw/t10k-images-idx3-ubyte.gz to ../data/MNIST/raw

Downloading http://yann.lecun.com/exdb/mnist/t10k-labels-idx1-ubyte.gz
Downloading http://yann.lecun.com/exdb/mnist/t10k-labels-idx1-ubyte.gz to ../data/MNIST/raw/t10k-labels-idx1-ubyte.gz
100%|████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████████| 4542/4542 [00:00<00:00, 20528587.03it/s]
Extracting ../data/MNIST/raw/t10k-labels-idx1-ubyte.gz to ../data/MNIST/raw

Train Epoch: 1 [0/60000 (0%)]	Loss: 2.282550
Train Epoch: 1 [640/60000 (1%)]	Loss: 1.385302
Train Epoch: 1 [1280/60000 (2%)]	Loss: 0.936717
...
Train Epoch: 14 [58880/60000 (98%)]	Loss: 0.003294
Train Epoch: 14 [59520/60000 (99%)]	Loss: 0.004645

Test set: Average loss: 0.0263, Accuracy: 9919/10000 (99%)
```
</p>
</details>


*Task 2: Part 2:* Creating our `NLP tasks` 

We create our `NLP tasks` as following:
- Extend the `Pytorch` docker, 
- Adding `HuggingFace` `pipelines`, make its `transformers` and `datasets` easily *cached*,
- Make these dockers *easily configurable* per each of the `NLP Tasks`: `text classification`, `question-answering`, and `text summarization` (and many more)
- Add a `Kafka consumer` and a `Kafka producer` to consume incoming messages and produce outgoing messages to `Kafka topics`.
- Allow `content-based routing` for the outgoing messages depending on the processing result of the imcoming messages.

<details>
<summary>Click here for more details.</summary>
<p>

1. The `NLP Task` docker are built for multiple tasks
- Named Entity Recognition
- Question Answering
- Sentiment Analysis
- Summarization
- Text Classification (multi-class/-label)

All of them built by extending the `nvcr.io/nvidia/pytorch:23.01-py3` `Docker` image. Each is configured by an `ini` file, for example for `named-entity-recognizer` image

```ini
[pipeline]
name=ner
model=Jean-Baptiste/roberta-large-ner-english
aggregation_strategy=simple
kwargs=aggregation_strategy

[consumer]
topic=screenrant-text-classifier-topic
bootstrap_servers=broker:29092
schema_registry=http://schema-registry:8081
avro_key_schema_file=screenrant-text-classifier-key.avsc
avro_val_schema_file=screenrant-text-classifier-value.avsc
consumer_group_id=named-entity-recognizer-cg
auto_offset_reset=earliest

[producer]
topic=screenrant-named-entity-recognizer-topic
bootstrap_servers=broker:29092
schema_registry=http://schema-registry:8081
avro_key_schema_file=screenrant-text-classifier-key.avsc
avro_val_schema_file=screenrant-named-entity-recognizer-value.avsc
target=full_text

[wranglers]
preprocess=input_text_classifier
postprocess=output_named_entity_recognizer
```

As shown above, each of them reads messages from a topic, e.g. `screenrant-text-classifier-topic`, and writes to another `screenrant-named-entity-recognizer-topic`, thus *chaining* the processing of messages through multi-stages (each served by an NLP task).

In each stage, the corresponding `NLP task` must handle messages with proper input and output formats, specified in `Avro` formats.

For example `screenrant-text-classifier-key.avsc`:
```json
{
    "type": "record",
    "name": "screentrant_text_classifier_key",
    "fields":[
        {"name":"link", "type": "string", "isOptional": false},
        {"name":"pub_date", "type": "string", "isOptional": false}
    ]
}
```

and `screenrant-text-classifier-value.avsc`:
```json
{
    "type": "record",
    "name": "screentrant_text_classifier_value",
    "fields":[
        {
            "name":"category", 
            "type": { "type": "array", "items": "string" }, 
            "default": []
        },
        {"name":"content", "type": "string"},
        {"name":"creator", "type": "string"},
        {"name":"description", "type": "string"},
        {"name":"enclosure_url", "type": "string"},
        {"name":"full_text", "type": "string"},
        {
            "name":"href_list",
            "type": { 
                "type": "array", 
                "items": { 
                    "name":"href", 
                    "type": "record", 
                    "fields": [ 
                        {"name":"content", "type": "string"},
                        {"name":"url", "type": "string"}  
                    ]
                } 
            }, 
            "default": []
        },
        {
            "name":"news_label_list",
            "type": { 
                "type": "array", 
                "items": { 
                    "name":"label", 
                    "type": "record", 
                    "fields": [ 
                        {"name":"name", "type": "string"},
                        {"name":"score", "type": "float"}  
                    ]
                } 
            }, 
            "default": []
        },
        {"name":"timestamp_pp", "type": "int"},
        {"name":"title", "type": "string"}
    ]
}
```

All `NLP task` are equipped with (via `ini` file configuration)
- an instance of `Kafka consumer` and `Kafka producer`,
- a configurable [HuggingFace](https://huggingface.co) `NLP pipeline`
- a pair of key/value `avro` schema files for messages in each of incoming and outgoing directions

Start `Kafka cluster` as usual, then create the *initial incoming and outgoing topics*:
```bash
./scripts/nlp/create_topics.sh
```

Start the `NLP cluster`
```bash
./scripts/nlp/start.sh
```

Feed the first batch of `ScreenRant` news by RSS feed:
```bash
./scripts/movie-rec/start.sh
```

Sometime later, feed another batch of `ScreenRant` news by RSS feed:
```bash
./scripts/movie-rec/download_current_rss.sh
```

Later, to stop the `NLP cluster`
```bash
./scripts/nlp/stop.sh
```

</p>
</details>

---

&nbsp;

**Task 3** - Data integration 

*Task 3 - Part 1: Integration of an `RSS Kafka Connect Source Connector` that enables capture of daily news from  [`ScreenRant`](https://screenrant.com)*

[`Screenrant`](https://screenrant.com) Screen Rant - headquartered in  Ogden, Utah, US - is arguably the most visited, non-corporate-owned movie and TV news site online. We cover the hot topics that movie and TV fans are looking for. Our readers are influencers in the movie and TV category: people others come to for recommendations on what to watch on TV and go see at the movies.  

Its (bi-)hourly feed [Screen Rant RSS Feed](https://screenrant.com/feed/) followed by 2M+ `Facebookers`, 246K+ `Twitters`. The feed contains approx. 100 latest news called `item` in `XML format`, with an example as below:
```xml
<item>
  <title>
    <![CDATA[
      Every Family Member Of Discovery’s Michael Burnham In Star Trek
    ]]>
  </title>
  <link>
    https://screenrant.com/star-trek-discovery-michael-burnham-family-members/
  </link>
  <dc:creator>
    <![CDATA[ John Orquiola ]]>
  </dc:creator>
  <enclosure url="https://static1.srcdn.com/wordpress/wp-content/uploads/2023/02/every-family-member-of-discovery-s-michael-burnham-in-star-trek.jpg" length="656" type="image/jpeg"/>
  <category>
    <![CDATA[ TV ]]>
  </category>
  <category>
    <![CDATA[ star trek discovery ]]>
  </category>
  <category>
    <![CDATA[ Star Trek ]]>
  </category>
  <description>
    <![CDATA[
    Star Trek: Discovery's Captain Michael Burnham is a member of two families and she has relatives in two different eras of Star Trek.
    ]]>
  </description>
  <content:encoded>
    <![CDATA[
      <p>Captain Michael Burnham (Sonequa Martin-Green) in <a href="https://screenrant.com/tag/star-trek-discovery/"><em><strong>Star Trek: Discovery</strong></em></a> is fortunate to be part of two families in two different eras. Burnham is <em>Discovery</em>&#39;s central character, and the focus on Michael as the primary lead distinguishes <em>Discovery </em>from other Star Trek series. In turn, Michael&#39;s rich backstory is supported by multiple parental figures, siblings, and a couple of notable love affairs with Lt. Ash Tyler (Shazad Latif) and Cleveland Booker (David Ajala).</p>
    ]]>
  </content:encoded>
  <pubDate>Mon, 20 Feb 2023 18:40:14 GMT</pubDate>
  <guid isPermaLink="true">
    https://screenrant.com/star-trek-discovery-michael-burnham-family-members/
  </guid>
</item>
```

Our purpose is to capture, extract, and transform it into the format show below,
```json
{
  "title":"Every Family Member Of Discovery’s Michael Burnham In Star Trek",
  "link":"https://screenrant.com/star-trek-discovery-michael-burnham-family-members/",
  "creator":"John Orquiola",
  "enclosure_url":"https://static1.srcdn.com/wordpress/wp-content/uploads/2023/02/every-family-member-of-discovery-s-michael-burnham-in-star-trek.jpg",
  "category":{"array":["TV","star trek discovery","Star Trek"]},
  "description":"Star Trek: Discovery's Captain Michael Burnham is a member of two families and she has relatives in two different eras of Star Trek.",
  "content":"<p>Captain Michael Burnham (Sonequa Martin-Green) in <a href=\"https://screenrant.com/tag/star-trek-discovery/\"><em><strong>Star Trek: Discovery</strong></em></a> is fortunate to be part of two families in two different eras. Burnham is <em>Discovery</em>&#39;s central character, and the focus on Michael as the primary lead distinguishes <em>Discovery </em>from other Star Trek series. In turn, Michael&#39;s rich backstory is supported by multiple parental figures, siblings, and a couple of notable love affairs with Lt. Ash Tyler (Shazad Latif) and Cleveland Booker (David Ajala).</p>",
  "pub_date":"Mon, 20 Feb 2023 18:40:14 GMT"
}
```

and later post-process all properties to gain `named entities`, clustering based on `categories`, and many other.
In addition `description` and `content` tags can be used to extract:
- URL links to `tags` on [`Screenrant`](https://screenrant.com), which is a nice way to resolve `tags` to this `movie news`.
- Emphasis by HTML `<em>` tags to elevate content to higher relevancy.

<details>
<summary>Click here for more details.</summary>
<p>

We use the [`FilePulse Source Connector`](https://streamthoughts.github.io/kafka-connect-file-pulse/)

1. First, we define a [`value schema`](../conf/movie-rec/screenrant-value.avsc) for the news `item` based on [this](https://streamthoughts.github.io/kafka-connect-file-pulse/docs/developer-guide/configuration/#defining-connect-record-schema):

```json
{
	"name": "screentrant_value",
	"type":"STRUCT",
	"fieldSchemas": {
		"link":{"type":"STRING", "isOptional":false},
		"pub_date":{"type":"STRING", "isOptional":false},
		"category": {"type":"ARRAY", "isOptional":true, "valueSchema": {"type": "STRING"}},
		"content":{"type":"STRING", "isOptional":false},
		"creator":{"type":"STRING", "isOptional":false},
		"description":{"type":"STRING", "isOptional":false},
		"enclosure_url":{"type":"STRING", "isOptional":false},
		"title":{"type":"STRING", "isOptional":false}
	}
}
```

2. The `Source Connector` is [defined in-line](../scripts/movie-rec/create_filepulse_connector.sh) as follow

```bash
curl -i -X PUT -H "Accept:application/json" -H  "Content-Type:application/json" \
  http://${connect_local_host}:${connect_port}/connectors/${connector}/config \
  -d '{
    "connector.class":"io.streamthoughts.kafka.connect.filepulse.source.FilePulseSourceConnector",
    "fs.listing.class":"io.streamthoughts.kafka.connect.filepulse.fs.LocalFSDirectoryListing",
    "fs.listing.directory.path":"/data/filepulse/xml",
    "fs.listing.filters":"io.streamthoughts.kafka.connect.filepulse.fs.filter.RegexFileListFilter",
    "fs.listing.interval.ms":10000,
    "fs.cleanup.policy.class": "io.streamthoughts.kafka.connect.filepulse.fs.clean.LogCleanupPolicy ",
    "file.filter.regex.pattern":".*\\.xml$",
    "offset.strategy":"name",
    "reader.xpath.expression":"/rss/channel/item",
    "reader.xpath.result.type":"NODESET",
    "reader.xml.force.array.on.fields":"category",
    "reader.xml.parser.validating.enabled":true,
    "reader.xml.parser.namespace.aware.enabled":true,
    "filters":"enclosure,content,pubDate,Exclude",
    "filters.enclosure.type":"io.streamthoughts.kafka.connect.filepulse.filter.MoveFilter",
    "filters.enclosure.source":"enclosure.url",
    "filters.enclosure.target":"enclosure_url",
    "filters.content.type":"io.streamthoughts.kafka.connect.filepulse.filter.RenameFilter",
    "filters.content.field":"encoded",
    "filters.content.target":"content",
    "filters.pubDate.type":"io.streamthoughts.kafka.connect.filepulse.filter.RenameFilter",
    "filters.pubDate.field":"pubDate",
    "filters.pubDate.target":"pub_date",
    "filters.Exclude.type":"io.streamthoughts.kafka.connect.filepulse.filter.ExcludeFilter",
    "filters.Exclude.fields":"enclosure,guid",
    "topic":"'${topic}'",
    "tasks.file.status.storage.bootstrap.servers":"'${broker_internal_host}':'${broker_internal_port}'",
    "tasks.file.status.storage.topic":"connect-file-pulse-status",
    "tasks.reader.class":"io.streamthoughts.kafka.connect.filepulse.fs.reader.LocalXMLFileInputReader",
    "tasks.max": 1,
    "value.connect.schema":"{ \"name\": \"screentrant_value\", \"type\":\"STRUCT\", \"fieldSchemas\": { \"link\":{\"type\":\"STRING\", \"isOptional\":false}, \"pub_date\":{\"type\":\"STRING\", \"isOptional\":false}, \"category\": {\"type\":\"ARRAY\", \"isOptional\":true, \"valueSchema\": {\"type\": \"STRING\"}}, \"content\":{\"type\":\"STRING\", \"isOptional\":false}, \"creator\":{\"type\":\"STRING\", \"isOptional\":false}, \"description\":{\"type\":\"STRING\", \"isOptional\":false}, \"enclosure_url\":{\"type\":\"STRING\", \"isOptional\":false}, \"title\":{\"type\":\"STRING\", \"isOptional\":false} } }"
  }'
```

The filter `filters.enclosure` uses a `MoveFilter` to move the `url` inside the tag `<enclosure>` into the (converted) `json` field `enclosure_url`, there is no need for `XML` attribute `size` `type` (although we might need if we want to propulate a website with those images, abeit the dimensions can be detected as well (?)).

It is worth to mention that to extract a single `RSS` feed containing `100` `items` of movie news into 100 `Kafka` messages, an `XPath` to identify the items need to be defined in the configuration
```json
"reader.xpath.expression":"/rss/channel/item",
```

It is decided to obtains the results as `NODESET`, since each of the properties of an `item` can have attribute that is valueable, such as `url` for the `enclosure` `XML` tag, so the configuration has to be done accordingly:
```json
"reader.xpath.result.type":"NODESET",
```

Note that the `FilePulse` library convert `XML` tags with names in form `<part1>:<part2>` into `<part2>`, for example `dc:creator` and `content:encoded` are converted into `creator` and `encoded`. Thus, the filter `filters.content` is used to rename the `encloded` into `content`. Filter `filters.pubDate` is to convert `pubDate` into `pub_date` for the sake of consistency. Last, filter `filters.Exclude` is used to drop the (extracted) `enclosure` and `guid` (since both `link` and `guid` have the same content and it makes more sense to refer back to the news using the `link` rather then `guid`, which is unfortunately not within our namespace).


And finally, the created `value.connect.schema`, which is to be sent to `Kafka Connect`, defined in just above, is `double-quote escaped`, `tabs removed`, and `linefeeds removed`, in order to convert into a `escaped` string that can be used in the configuration:
```json
"value.connect.schema":"{ \"name\": \"screentrant_value\", \"type\":\"STRUCT\", \"fieldSchemas\": { \"link\":{\"type\":\"STRING\", \"isOptional\":false}, \"pub_date\":{\"type\":\"STRING\", \"isOptional\":false}, \"category\": {\"type\":\"ARRAY\", \"isOptional\":true, \"valueSchema\": {\"type\": \"STRING\"}}, \"content\":{\"type\":\"STRING\", \"isOptional\":false}, \"creator\":{\"type\":\"STRING\", \"isOptional\":false}, \"description\":{\"type\":\"STRING\", \"isOptional\":false}, \"enclosure_url\":{\"type\":\"STRING\", \"isOptional\":false}, \"title\":{\"type\":\"STRING\", \"isOptional\":false} } }"
```

The [Developer Guide](https://streamthoughts.github.io/kafka-connect-file-pulse/docs/developer-guide/) is amazingly details, although it is not written for beginners. It is worth to study the connector by the following articles (for file-based or anything that can be turned into an XML file)
- [Kafka Connect FilePulse - One Connector to Ingest them All!](https://medium.com/streamthoughts/kafka-connect-filepulse-one-connector-to-ingest-them-all-faed018a725c)
- [Streaming data into Kafka S01/E02 - Loading XML file](https://dev.to/fhussonnois/streaming-data-into-kafka-s01-e02-loading-xml-file-529i)
- [Ingesting XML data into Kafka - Option 3: Kafka Connect FilePulse connector](https://rmoff.net/2020/10/01/ingesting-xml-data-into-kafka-option-3-kafka-connect-filepulse-connector/)

Note that it is important the the `XML` files (feeds) location is configured as 
```json
"fs.listing.directory.path":"/data/filepulse/xml",
```

thus, they have to be downloaded and placed into `$PWD/kafka-ce/connect/data`, which is mapped to the local volume by [docker-compose-kafka-ce.yml](../docker-compose-kafka-ce.yml)

```yaml
  ####################
  # connect
  ####################
  connect:
    image: confluentinc/cp-kafka-connect:7.3.1
    hostname: connect
    container_name: connect
    ...
    volumes:
      - $PWD/kafka-ce/connect/data:/data
      - $PWD/kafka-ce/plugins:/usr/share/confluent-hub-components
    restart: always
```

3. Run the test

First, (setup Docker, test the setup, and then) start Kafka
```bash
./scripts/kafka/setup.sh
./scripts/kafka/start_after_setup.sh
```

Setup the test:
```bash
./scripts/movie-rec/start.sh
```

What does it do? Lets take a look at its content:
```bash
# Download the current RSS feed from https://screenrant.com/feed/
# In production it is recommended to run a cronjob, note that the feed is updated frequently
# We don't worry about duplication, since the messages are fed into Kafka and it will eliminate duplicates - depending on our choice for unique constraints
./scripts/movie-rec/download_current_rss.sh

# List the current Connect plugins
# What we need is the "io.streamthoughts.kafka.connect.filepulse.source.FilePulseSourceConnector"
./scripts/movie-rec/list_connect_plugins.sh

# List the current connector instances
# It could show an earlier version of the "filepulse-screenrant" connector, but don't worry, it will be updated
./scripts/movie-rec/list_connectors.sh

# List the current topics
# It could show that the topic "topic-screenrant" exists, but that will have no effect
./scripts/movie-rec/list_topics.sh

# List the current subject in the "schema registry" of the Kafka cluster
# It could show that the subject "topic-screenrant-value" exists, this script will update it with a new version
./scripts/movie-rec/list_subjects.sh

# Create the FilePulse connector with the configuration shown above to read XML messages
./scripts/movie-rec/create_filepulse_connector.sh ${topic} ${connector} ${test_internal_ms_setup}
```

Run the test (can be repeated multiple times)
```bash
./scripts/movie-rec/run_multiple.sh
```

What does it do? Lets take a look at its content:
```bash
# Wait until the connector instance becomes available
./scripts/movie-rec/wait_for_connector.sh ${connector}

# Wait until the schema registry subject becomes available
./scripts/movie-rec/wait_for_subject.sh ${subject}

# Wait until the topic becomes available
./scripts/movie-rec/wait_for_topic.sh ${topic}

# The FilePulse source connector instance will 
# - automatically kick-in, 
# - reading messages, 
# - process them according to the "filters" instructions
# - convert them from XML into AVRO messages according to the schema (now) stored in the schema registry
# - produce these messages into the topic

# Test consuming messages with in a number of seconds
# The consumer_group variable is used to define a consumer group,
# that will be used to reset the consumer offsets if messages need to be reread
./scripts/movie-rec/consume_messages.sh ${topic} ${timeout_ms} ${consumer_group}
echo ''

# Here messages are reread and reprocessed
echo Reset consumer offset and consume again ✅
./scripts/movie-rec/consume_messages.sh ${topic} ${timeout_ms} ${consumer_group}
```

Stop the test
```bash
./scripts/movie-rec/run_multiple.sh
```

What does it do? Lets take a look at its content:
```bash
# Subject, topic, and connector instance are deleted to cleanup the cluster
./scripts/movie-rec/delete_subject.sh ${subject}
./scripts/movie-rec/delete_topic.sh ${topic}
./scripts/movie-rec/delete_connector.sh ${connector}

# Downloaded RSS files are removed
./scripts/movie-rec/remove_all_downloaded_rss.sh
```

Console output listed below, some truncated for ease to read,
```bash
Downloading data into for filepulse folder ...
kafka-ce/connect/data/filepulse/xmlscreenrant-rss-1677007251244.xml is downloaded. ✅

Listing all available plugins ...
curl -s -XGET http://localhost:8083/connector-plugins | jq '.[].class'
"io.confluent.connect.jdbc.JdbcSinkConnector"
"streams.kafka.connect.sink.Neo4jSinkConnector"
"com.github.jcustenborder.kafka.connect.spooldir.SpoolDirAvroSourceConnector"
"com.github.jcustenborder.kafka.connect.spooldir.SpoolDirBinaryFileSourceConnector"
"com.github.jcustenborder.kafka.connect.spooldir.SpoolDirCsvSourceConnector"
"com.github.jcustenborder.kafka.connect.spooldir.SpoolDirJsonSourceConnector"
"com.github.jcustenborder.kafka.connect.spooldir.SpoolDirLineDelimitedSourceConnector"
"com.github.jcustenborder.kafka.connect.spooldir.SpoolDirSchemaLessJsonSourceConnector"
"com.github.jcustenborder.kafka.connect.spooldir.elf.SpoolDirELFSourceConnector"
"io.confluent.connect.jdbc.JdbcSourceConnector"
"io.debezium.connector.mysql.MySqlConnector"
"io.streamthoughts.kafka.connect.filepulse.source.FilePulseSourceConnector"
"org.apache.kafka.connect.mirror.MirrorCheckpointConnector"
"org.apache.kafka.connect.mirror.MirrorHeartbeatConnector"
"org.apache.kafka.connect.mirror.MirrorSourceConnector"
"streams.kafka.connect.source.Neo4jSourceConnector"

Listing all connectors ...
curl -s -XGET http://localhost:8083/connectors | jq '.[]'

List all topics ...
docker exec -it broker /bin/kafka-topics --bootstrap-server broker:29092 --list
__consumer_offsets
__transaction_state
_confluent-ksql-default__command_topic
_schemas
default_ksql_processing_log
docker-connect-configs
docker-connect-offsets
docker-connect-status

List all current subjects ...
curl --silent -X GET http://localhost:8081/subjects | jq .[]

Creating filepulse connector ...
curl -i -X PUT -H Accept:application/json -H  Content-Type:application/json     http://localhost:8083/connectors/screenrant-filepulse-connector/config     -d '{
        connector.class:io.streamthoughts.kafka.connect.filepulse.source.FilePulseSourceConnector,
        fs.listing.class:io.streamthoughts.kafka.connect.filepulse.fs.LocalFSDirectoryListing,
        fs.listing.directory.path:/data/filepulse/xml,
        fs.listing.filters:io.streamthoughts.kafka.connect.filepulse.fs.filter.RegexFileListFilter,
        fs.listing.interval.ms:${internal_ms_setup},
        fs.cleanup.policy.class: io.streamthoughts.kafka.connect.filepulse.fs.clean.LogCleanupPolicy ,
        file.filter.regex.pattern:.*\.xml,
        offset.strategy:name,
        reader.xpath.expression:/rss/channel/item,
        reader.xpath.result.type:NODESET,
        reader.xml.force.array.on.fields:category,
        reader.xml.parser.validating.enabled:true,
        reader.xml.parser.namespace.aware.enabled:true,
        filters:enclosure,content,pubDate,Exclude,
        filters.enclosure.type:io.streamthoughts.kafka.connect.filepulse.filter.MoveFilter,
        filters.enclosure.source:enclosure.url,
        filters.enclosure.target:enclosure_url,
        filters.content.type:io.streamthoughts.kafka.connect.filepulse.filter.RenameFilter,
        filters.content.field:encoded,
        filters.content.target:content,
        filters.pubDate.type:io.streamthoughts.kafka.connect.filepulse.filter.RenameFilter,
        filters.pubDate.field:pubDate,
        filters.pubDate.target:pub_date,
        filters.Exclude.type:io.streamthoughts.kafka.connect.filepulse.filter.ExcludeFilter,
        filters.Exclude.fields:enclosure,guid,
        topic:${topic},
        tasks.file.status.storage.bootstrap.servers:${broker_internal_host}:${broker_internal_port},
        tasks.file.status.storage.topic:connect-file-pulse-status,
        tasks.reader.class:io.streamthoughts.kafka.connect.filepulse.fs.reader.LocalXMLFileInputReader,
        tasks.max: 1,
        value.connect.schema:{ "name": "screentrant_value", "type":"STRUCT", "fieldSchemas": { "link":{"type":"STRING", "isOptional":false}, "pub_date":{"type":"STRING", "isOptional":false}, "category": {"type":"ARRAY", "isOptional":true, "valueSchema": {"type": "STRING"}}, "content":{"type":"STRING", "isOptional":false}, "creator":{"type":"STRING", "isOptional":false}, "description":{"type":"STRING", "isOptional":false}, "enclosure_url":{"type":"STRING", "isOptional":false}, "title":{"type":"STRING", "isOptional":false} } }
    }'

HTTP/1.1 201 Created
Date: Tue, 21 Feb 2023 19:20:53 GMT
Location: http://localhost:8083/connectors/screenrant-filepulse-connector
Content-Type: application/json
Content-Length: 2407
Server: Jetty(9.4.48.v20220622)

{"name":"screenrant-filepulse-connector","config":{"connector.class":"io.streamthoughts.kafka.connect.filepulse.source.FilePulseSourceConnector","fs.listing.class":"io.streamthoughts.kafka.connect.filepulse.fs.LocalFSDirectoryListing","fs.listing.directory.path":"/data/filepulse/xml","fs.listing.filters":"io.streamthoughts.kafka.connect.filepulse.fs.filter.RegexFileListFilter","fs.listing.interval.ms":"10000","fs.cleanup.policy.class":"io.streamthoughts.kafka.connect.filepulse.fs.clean.LogCleanupPolicy ","file.filter.regex.pattern":".*\\.xml$","offset.strategy":"name","reader.xpath.expression":"/rss/channel/item","reader.xpath.result.type":"NODESET","reader.xml.force.array.on.fields":"category","reader.xml.parser.validating.enabled":"true","reader.xml.parser.namespace.aware.enabled":"true","filters":"enclosure,content,pubDate,Exclude","filters.enclosure.type":"io.streamthoughts.kafka.connect.filepulse.filter.MoveFilter","filters.enclosure.source":"enclosure.url","filters.enclosure.target":"enclosure_url","filters.content.type":"io.streamthoughts.kafka.connect.filepulse.filter.RenameFilter","filters.content.field":"encoded","filters.content.target":"content","filters.pubDate.type":"io.streamthoughts.kafka.connect.filepulse.filter.RenameFilter","filters.pubDate.field":"pubDate","filters.pubDate.target":"pub_date","filters.Exclude.type":"io.streamthoughts.kafka.connect.filepulse.filter.ExcludeFilter","filters.Exclude.fields":"enclosure,guid","topic":"screenrant-topic","tasks.file.status.storage.bootstrap.servers":"broker:29092","tasks.file.status.storage.topic":"connect-file-pulse-status","tasks.reader.class":"io.streamthoughts.kafka.connect.filepulse.fs.reader.LocalXMLFileInputReader","tasks.max":"1","value.connect.schema":"{ \"name\": \"screentrant_rss_value\", \"type\":\"STRUCT\", \"fieldSchemas\": { \"link\":{\"type\":\"STRING\", \"isOptional\":false}, \"pub_date\":{\"type\":\"STRING\", \"isOptional\":false}, \"category\": {\"type\":\"ARRAY\", \"isOptional\":true, \"valueSchema\": {\"type\": \"STRING\"}}, \"content\":{\"type\":\"STRING\", \"isOptional\":false}, \"creator\":{\"type\":\"STRING\", \"isOptional\":false}, \"description\":{\"type\":\"STRING\", \"isOptional\":false}, \"enclosure_url\":{\"type\":\"STRING\", \"isOptional\":false}, \"title\":{\"type\":\"STRING\", \"isOptional\":false} } }","name":"screenrant-filepulse-connector"},"tasks":[],"type":"source"}
Filepulse connector created ✅

Wait for connector screenrant-filepulse-connector ...
screenrant-filepulse-connector connector ready ✅
Wait for the subject screenrant-topic-value be ready ...

List all versions of screenrant-topic-value...
curl --silent -X GET http://localhost:8081/subjects/screenrant-topic-value/versions | jq
[
  1
]

Wait for topic screenrant-topic to be ready...
Topic screenrant-topic with replications ready ✅
Reset all consumer offsets of filepulse-consumer group ...
docker exec -it broker /bin/kafka-consumer-groups     --bootstrap-server broker:29092     --group screenrant-consumer-group --reset-offsets --to-earliest --all-topics --execute;


GROUP                          TOPIC                          PARTITION  NEW-OFFSET     
Consumer offsets reset ✅

Consume messages ...
docker exec -it schema-registry kafka-avro-console-consumer      --bootstrap-server broker:29092     --topic screenrant-topic --group screenrant-consumer-group --from-beginning --timeout-ms 5000     --property schema.registry.url=http://schema-registry:8081

{"pub_date":"Tue, 21 Feb 2023 19:08:11 GMT","creator":"Saylee Padwal","enclosure_url":"https://static1.srcdn.com/wordpress/wp-content/uploads/2023/02/90-day-fiance-s-daniele-gates-1.jpg","link":"https://screenrant.com/90-day-fiance-stars-sketchy-financial-decisions-daniele/","description":"\n                                            From living questionable lavish lifestyles one day to going bankrupt the next, 90 Day Fiancé stars and their money matters are extremely shady.\n                                        ","category":{"array":["Reality TV","90 Day Fiance: The Other Way","Love In Paradise: The Caribbean","90 Day Fiance"]},"title":"Daniele & Other 90 Day Fiancé Stars Who Made Sketchy Financial Decisions","content":"\n                                                                                                                    <p>The<strong><em> <a href=\"https://screenrant.com/tag/90-day-fiance/\">90 Day Fianc&eacute;</a></em></strong> franchise has a long history of introducing several financially irresponsible cast members who have no idea how to make, save, or use money. The TLC show essentially has an American partner falling in love overseas and bringing their international lovers over to the United States to get married. Oftentimes, these are people who can barely earn a living, and are wanting to take on the added responsibility of financially supporting a second human being. Sometimes, things can become worse when the international partner may actually believe that their husband or wife-to-be is the richest person they&rsquo;ll ever meet.</p>\n    \n                                                                                            "}
{"pub_date":"Tue, 21 Feb 2023 19:05:15 GMT","creator":"Francesco Cacciatore","enclosure_url":"https://static1.srcdn.com/wordpress/wp-content/uploads/2023/02/jodio-joestar-and-giorno-giovanna-from-jojo-s-bizarre-adventure.jpg","link":"https://screenrant.com/jojolands-jojo-part-9-officially-remake-golden-wind-better/","description":"\n                                            The JOJOLands takes Golden Wind's premise of a criminal protagonist much further, improving key aspects of Giorno Giovanna's story.\n                                        ","category":{"array":["Anime","Jojo&#039;s Bizarre Adventure"]},"title":"JoJoLands Is Officially A Remake Of JJBA Golden Wind, But Better","content":"\n                                                                                                                    <p>Part 9 of <a href=\"https://screenrant.com/tag/jojos-bizarre-adventure/\"><strong><em>JoJo&#39;s Bizarre Adventure</em> - <em>The JOJOLands</em></strong></a> has begun, and it immediately confirms fans&#39; belief that this new installment in Hiroiko Araki&#39;s generational saga will be heavily inspired by <strong>Part 5 -</strong> <strong><em>Golden Wind</em></strong>. However, <em>The JOJOLands</em> takes <em>Golden Wind</em>&#39;s premise much further, improving key aspects of Giorno Giovanna&#39;s story.</p>\n    \n                                                                                            "}
{"pub_date":"Tue, 21 Feb 2023 19:03:39 GMT","creator":"Brandon Louis","enclosure_url":"https://static1.srcdn.com/wordpress/wp-content/uploads/2022/10/Pierce-Brosnan-as-James-Bond-with-an-assault-rifle.jpg","link":"https://screenrant.com/james-bond-liam-neeson-turned-down-role/","description":"\n                                            One popular action star reveals he rejected the role as the MI6 spy James Bond because his wife told him she would not marry him if he did.\n                                        ","category":{"array":["Movies","James Bond"]},"title":"One Action Star Rejected James Bond Role Because His Wife Refused To Marry Him","content":"\n                                                                                                                    <p>One popular action star revealed that they rejected the role as <a href=\"https://screenrant.com/tag/james-bond/\"><strong>James Bond</strong></a> because his wife would refuse to marry him if he did. Originally created in 1953 by novelist Ian Fleming, the charming spy took the world by storm in 1962 with the franchise&#39;s first feature film,<em> Dr. No</em>. For over six decades and 25 Eon Productions films, six lead actors have portrayed Bond to include Sean Connery, George Lazenby, Roger Moore, Timothy Dalton, Pierce Brosnan, and Daniel Craig.</p>\n    \n                                                                                            "}
...
{"pub_date":"Tue, 21 Feb 2023 14:50:16 GMT","creator":"Jessica Smith","enclosure_url":"https://static1.srcdn.com/wordpress/wp-content/uploads/2023/02/winnie-the-pooh-blood-and-honey-owl-and-rabbit.jpg","link":"https://screenrant.com/winnie-pooh-blood-honey-owl-rabbit-eaten-what-happened/","description":"\n                                            Owl and Rabbit were with young Christopher Robin in Winnie-The-Pooh: Blood and Honey, but why did they disappear, was their fate the same as Eeyore’s?\n                                        ","category":{"array":["Movies","Winnie the Pooh: Blood and Honey"]},"title":"What Happened To Owl & Rabbit In Blood & Honey (Were They Eaten?)","content":"\n                                                                                                                    <p>Owl and Rabbit only appear at the beginning of <a href=\"https://screenrant.com/tag/winnie-the-pooh-blood-and-honey/\"><strong><em>Winnie-The-Pooh: Blood and Honey</em></strong></a>, but it is not clear what happened to them. <em>Winnie-The-Pooh: Blood and Honey </em>is the first horror/slasher movie using beloved Disney characters that have recently come into the public domain. Rhys Frake-Waterfield wrote, directed, and produced <em>Blood and Honey </em>with the intention of it releasing as a one-off indie film, but its success has smashed expectations and made over $2.5 million at the box office so far. It has mixed critical reviews, but its box office success has meant a sequel is already in the works. One key job that the sequel could have is resolving some unanswered <em>Blood and Honey</em> questions, such as what exactly happened to Rabbit and Owl.</p>\n    \n                                                                                            "}
{"pub_date":"Tue, 21 Feb 2023 14:50:15 GMT","creator":"Alix Batte","enclosure_url":"https://static1.srcdn.com/wordpress/wp-content/uploads/2023/02/star-wars-disney-darth-vader-more-powerful-lucas.jpg","link":"https://screenrant.com/star-wars-disney-darth-vader-more-powerful-lucas/","description":"\n                                            Darth Vader became an iconic villain under the direction of George Lucas, but Disney’s Star Wars movies make show how powerful he truly was.\n\n                                        ","category":{"array":["Movies","Star Wars (Franchise)","Star Wars Rebels","Star Wars: Rogue One","Obi-Wan Kenobi"]},"title":"6 Times Disney's Darth Vader Was More Powerful Than George Lucas'","content":"\n                                                                                                                    <p>George Lucas never let Darth Vader go to waste in the <a href=\"https://screenrant.com/tag/star-wars/\"><strong><em>Star Wars</em></strong></a> movies he wrote, but now that the story is in the hands of Disney, the villain&rsquo;s power has never been more evident. With the benefit of having access to more advanced special effects and elevated stunts than the earlier movies did, Disney&rsquo;s <em>Star Wars</em> projects wasted no time showcasing just how frightening Vader could be. While the new <em>Star Wars</em> content has lots of material to explore, one thing that stays constant is Darth Vader&rsquo;s ability to terrify.</p>\n    \n                                                                                            "}
{"pub_date":"Tue, 21 Feb 2023 14:45:17 GMT","creator":"Nathan Graham-Lowery","enclosure_url":"https://static1.srcdn.com/wordpress/wp-content/uploads/2023/02/happy-death-day-and-freaky-director-christopher-landon-addresses-potential-crossover.jpg","link":"https://screenrant.com/happy-death-day-freaky-crossover-future-development-details/","description":"\n                                            Plans for a potential Happy Death Day &amp; Freaky crossover are clarified by director Christopher Landon, addressing previous comments on the idea.\n                                        ","category":{"array":["Movies","Freaky","Happy Death Day"]},"title":"Happy Death Day & Freaky Crossover Plans Clarified By Director","content":"\n                                                                                                                    <p>Director Christopher Landon weighs in on the discussion surrounding a potential <a href=\"https://screenrant.com/tag/happy-death-day/\"><strong><em>Happy Death Day</em></strong></a> and <a href=\"https://screenrant.com/tag/freaky/\"><strong><em>Freaky</em></strong></a><strong><em> </em></strong>crossover, addressing the current likelihood on the project ever going ahead. Landon directed 2017&#39;s<em> Happy Death Day</em>, which stars Jessica Rothe as a college student caught in a time loop on her birthday, forced to relive her shocking murder over and over until she unmasks her killer. The director would helm the sequel, <em>Happy Death Day 2 U</em>, before working on 2020&#39;s <em>Freaky</em>, which starred Kathryn Newton and Vince Vaughn as a teenage girl and serial killer who are unintentionally subjected to a body swap.</p>\n    \n                                                                                            "}
[2023-02-21 19:23:08,754] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 100 messages


Reset consumer offset and consume again ✅
Reset all consumer offsets of filepulse-consumer group ...
docker exec -it broker /bin/kafka-consumer-groups     --bootstrap-server broker:29092     --group screenrant-consumer-group --reset-offsets --to-earliest --all-topics --execute;


GROUP                          TOPIC                          PARTITION  NEW-OFFSET     
screenrant-consumer-group      screenrant-topic               0          0              
Consumer offsets reset ✅

Consume messages ...
docker exec -it schema-registry kafka-avro-console-consumer      --bootstrap-server broker:29092     --topic screenrant-topic --group screenrant-consumer-group --from-beginning --timeout-ms 5000     --property schema.registry.url=http://schema-registry:8081

{"pub_date":"Tue, 21 Feb 2023 19:08:11 GMT","creator":"Saylee Padwal","enclosure_url":"https://static1.srcdn.com/wordpress/wp-content/uploads/2023/02/90-day-fiance-s-daniele-gates-1.jpg","link":"https://screenrant.com/90-day-fiance-stars-sketchy-financial-decisions-daniele/","description":"\n                                            From living questionable lavish lifestyles one day to going bankrupt the next, 90 Day Fiancé stars and their money matters are extremely shady.\n                                        ","category":{"array":["Reality TV","90 Day Fiance: The Other Way","Love In Paradise: The Caribbean","90 Day Fiance"]},"title":"Daniele & Other 90 Day Fiancé Stars Who Made Sketchy Financial Decisions","content":"\n                                                                                                                    <p>The<strong><em> <a href=\"https://screenrant.com/tag/90-day-fiance/\">90 Day Fianc&eacute;</a></em></strong> franchise has a long history of introducing several financially irresponsible cast members who have no idea how to make, save, or use money. The TLC show essentially has an American partner falling in love overseas and bringing their international lovers over to the United States to get married. Oftentimes, these are people who can barely earn a living, and are wanting to take on the added responsibility of financially supporting a second human being. Sometimes, things can become worse when the international partner may actually believe that their husband or wife-to-be is the richest person they&rsquo;ll ever meet.</p>\n    \n                                                                                            "}
{"pub_date":"Tue, 21 Feb 2023 19:05:15 GMT","creator":"Francesco Cacciatore","enclosure_url":"https://static1.srcdn.com/wordpress/wp-content/uploads/2023/02/jodio-joestar-and-giorno-giovanna-from-jojo-s-bizarre-adventure.jpg","link":"https://screenrant.com/jojolands-jojo-part-9-officially-remake-golden-wind-better/","description":"\n                                            The JOJOLands takes Golden Wind's premise of a criminal protagonist much further, improving key aspects of Giorno Giovanna's story.\n                                        ","category":{"array":["Anime","Jojo&#039;s Bizarre Adventure"]},"title":"JoJoLands Is Officially A Remake Of JJBA Golden Wind, But Better","content":"\n                                                                                                                    <p>Part 9 of <a href=\"https://screenrant.com/tag/jojos-bizarre-adventure/\"><strong><em>JoJo&#39;s Bizarre Adventure</em> - <em>The JOJOLands</em></strong></a> has begun, and it immediately confirms fans&#39; belief that this new installment in Hiroiko Araki&#39;s generational saga will be heavily inspired by <strong>Part 5 -</strong> <strong><em>Golden Wind</em></strong>. However, <em>The JOJOLands</em> takes <em>Golden Wind</em>&#39;s premise much further, improving key aspects of Giorno Giovanna&#39;s story.</p>\n    \n                                                                                            "}
{"pub_date":"Tue, 21 Feb 2023 19:03:39 GMT","creator":"Brandon Louis","enclosure_url":"https://static1.srcdn.com/wordpress/wp-content/uploads/2022/10/Pierce-Brosnan-as-James-Bond-with-an-assault-rifle.jpg","link":"https://screenrant.com/james-bond-liam-neeson-turned-down-role/","description":"\n                                            One popular action star reveals he rejected the role as the MI6 spy James Bond because his wife told him she would not marry him if he did.\n                                        ","category":{"array":["Movies","James Bond"]},"title":"One Action Star Rejected James Bond Role Because His Wife Refused To Marry Him","content":"\n                                                                                                                    <p>One popular action star revealed that they rejected the role as <a href=\"https://screenrant.com/tag/james-bond/\"><strong>James Bond</strong></a> because his wife would refuse to marry him if he did. Originally created in 1953 by novelist Ian Fleming, the charming spy took the world by storm in 1962 with the franchise&#39;s first feature film,<em> Dr. No</em>. For over six decades and 25 Eon Productions films, six lead actors have portrayed Bond to include Sean Connery, George Lazenby, Roger Moore, Timothy Dalton, Pierce Brosnan, and Daniel Craig.</p>\n    \n                                                                                            "}
...
{"pub_date":"Tue, 21 Feb 2023 14:50:16 GMT","creator":"Jessica Smith","enclosure_url":"https://static1.srcdn.com/wordpress/wp-content/uploads/2023/02/winnie-the-pooh-blood-and-honey-owl-and-rabbit.jpg","link":"https://screenrant.com/winnie-pooh-blood-honey-owl-rabbit-eaten-what-happened/","description":"\n                                            Owl and Rabbit were with young Christopher Robin in Winnie-The-Pooh: Blood and Honey, but why did they disappear, was their fate the same as Eeyore’s?\n                                        ","category":{"array":["Movies","Winnie the Pooh: Blood and Honey"]},"title":"What Happened To Owl & Rabbit In Blood & Honey (Were They Eaten?)","content":"\n                                                                                                                    <p>Owl and Rabbit only appear at the beginning of <a href=\"https://screenrant.com/tag/winnie-the-pooh-blood-and-honey/\"><strong><em>Winnie-The-Pooh: Blood and Honey</em></strong></a>, but it is not clear what happened to them. <em>Winnie-The-Pooh: Blood and Honey </em>is the first horror/slasher movie using beloved Disney characters that have recently come into the public domain. Rhys Frake-Waterfield wrote, directed, and produced <em>Blood and Honey </em>with the intention of it releasing as a one-off indie film, but its success has smashed expectations and made over $2.5 million at the box office so far. It has mixed critical reviews, but its box office success has meant a sequel is already in the works. One key job that the sequel could have is resolving some unanswered <em>Blood and Honey</em> questions, such as what exactly happened to Rabbit and Owl.</p>\n    \n                                                                                            "}
{"pub_date":"Tue, 21 Feb 2023 14:50:15 GMT","creator":"Alix Batte","enclosure_url":"https://static1.srcdn.com/wordpress/wp-content/uploads/2023/02/star-wars-disney-darth-vader-more-powerful-lucas.jpg","link":"https://screenrant.com/star-wars-disney-darth-vader-more-powerful-lucas/","description":"\n                                            Darth Vader became an iconic villain under the direction of George Lucas, but Disney’s Star Wars movies make show how powerful he truly was.\n\n                                        ","category":{"array":["Movies","Star Wars (Franchise)","Star Wars Rebels","Star Wars: Rogue One","Obi-Wan Kenobi"]},"title":"6 Times Disney's Darth Vader Was More Powerful Than George Lucas'","content":"\n                                                                                                                    <p>George Lucas never let Darth Vader go to waste in the <a href=\"https://screenrant.com/tag/star-wars/\"><strong><em>Star Wars</em></strong></a> movies he wrote, but now that the story is in the hands of Disney, the villain&rsquo;s power has never been more evident. With the benefit of having access to more advanced special effects and elevated stunts than the earlier movies did, Disney&rsquo;s <em>Star Wars</em> projects wasted no time showcasing just how frightening Vader could be. While the new <em>Star Wars</em> content has lots of material to explore, one thing that stays constant is Darth Vader&rsquo;s ability to terrify.</p>\n    \n                                                                                            "}
{"pub_date":"Tue, 21 Feb 2023 14:45:17 GMT","creator":"Nathan Graham-Lowery","enclosure_url":"https://static1.srcdn.com/wordpress/wp-content/uploads/2023/02/happy-death-day-and-freaky-director-christopher-landon-addresses-potential-crossover.jpg","link":"https://screenrant.com/happy-death-day-freaky-crossover-future-development-details/","description":"\n                                            Plans for a potential Happy Death Day &amp; Freaky crossover are clarified by director Christopher Landon, addressing previous comments on the idea.\n                                        ","category":{"array":["Movies","Freaky","Happy Death Day"]},"title":"Happy Death Day & Freaky Crossover Plans Clarified By Director","content":"\n                                                                                                                    <p>Director Christopher Landon weighs in on the discussion surrounding a potential <a href=\"https://screenrant.com/tag/happy-death-day/\"><strong><em>Happy Death Day</em></strong></a> and <a href=\"https://screenrant.com/tag/freaky/\"><strong><em>Freaky</em></strong></a><strong><em> </em></strong>crossover, addressing the current likelihood on the project ever going ahead. Landon directed 2017&#39;s<em> Happy Death Day</em>, which stars Jessica Rothe as a college student caught in a time loop on her birthday, forced to relive her shocking murder over and over until she unmasks her killer. The director would helm the sequel, <em>Happy Death Day 2 U</em>, before working on 2020&#39;s <em>Freaky</em>, which starred Kathryn Newton and Vince Vaughn as a teenage girl and serial killer who are unintentionally subjected to a body swap.</p>\n    \n                                                                                            "}
[2023-02-21 19:23:23,409] ERROR Error processing message, terminating consumer process:  (kafka.tools.ConsoleConsumer$)
org.apache.kafka.common.errors.TimeoutException
Processed a total of 100 messages

Delete screenrant-topic-value subject ...
curl --silent -X DELETE http://localhost:8081/subjects/screenrant-topic-value | jq .[]
1

List all current subjects ...
curl --silent -X GET http://localhost:8081/subjects | jq .[]

Delete topic screenrant-topic ...
docker exec -it broker /bin/kafka-topics     --delete --topic      --bootstrap-server broker:29092
screenrant-topic deleted ✅

Delete connector ...
curl --silent -X DELETE http://localhost:8083/connectors/screenrant-filepulse-connector | jq .[]
screenrant-filepulse-connector connector deleted ✅
Removing processed data from filepulse ...
Processed data in filepulse deleted ✅
```
</p>
</details>

*Task 3 - Part 2:* Integration of a `SpoolDir TSV Source Connector` that enables to import the `IMDb dataset`.

(**TBC**)