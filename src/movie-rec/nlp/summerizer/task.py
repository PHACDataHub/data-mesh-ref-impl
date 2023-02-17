from transformers import pipeline
import pandas as pd

def display(model_outputs):
    df = pd.DataFrame(model_outputs)
    print(df)

text = """Who says Valentine's Day can't have some jokes?
Director Todd Phillips took to Instagram to unveil the first look at Lady Gaga in the sequel Joker: Folie à Deux.
While her role is currently under wraps, all signs appear to point to the multi-hyphenate portraying iconic DC character Harley Quinn.
The Joker sequel is set to release on October 4, 2024.
Gaga isn't alone in the image, which sees the return of Joaquin Phoenix's Arthur Fleck/Joker.
He's complete in marred clown makeup and clearly happy to be in the embrace of her character.
Plot details are not known at the moment.
However, this image appears to correlate with Harley Quinn's origin as Joker's psychiatrist in Arkham Asylum, the presumed location for the sequel.
The ending of Joker found Arthur having his way in the famed Gotham facility."""

summarizer = pipeline("summarization")
outputs = summarizer(text, max_length=100, clean_up_tokenization_spaces=True)
print(outputs[0]['summary_text'], '\n')
