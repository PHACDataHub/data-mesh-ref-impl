## Movie Recommendation

Brief Description:
- the integration of NLP containers (per task as shown), with pre-trained datasets, and datasets for fine-tuning,
- some sort of descriptive configuration (in Confluent Cloud there is a Stream Designer, which is very convenient for orchestrating the workflow pipeline mesh),
- some additional movie info databases (from sources highlighted in the diagram), perhaps some cloud storage for large binary data (to avoid long download time, shorten setup time)
- some harvesters to collect movie news (from sources highlighted in the diagram)
- the one that will probably takes large portion of time is to construct a UI which capable to issue formal and “natural language” queries, based on React, communicating via GraphQL, and capable of doing some good visualizations.

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
  + Integration of an `RSS Kafka Connect Source Connector` that enables capture of daily news from  [`ScreenRant`](https://screenrant.com)
  + Integration of a `SpoolDir TSV Source Connector` that enables to import the `IMDb dataset`.
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

**Task 2** `NLP` task as `Docker` image

A virtual machine is created in the `Google Cloud Platform`:
- `n1-standard-8`, 8 vCPU, 30GB RAM, `threads-per-core=2`, `visible-core-count=4`
- `NVIDIA T4`
- `ubuntu-2204-jammy-v20230114`
- 100 GB persistent disk
- access via SSH (keys)
- allow HTTP/HTTPS (with provisioned static internal/external IPs)
