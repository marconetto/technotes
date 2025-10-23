# LLM

An LLM (Large Language Model) is an AI system trained on larges amount of data so it can understand and generate human-like language.
It predicts the next word in a sequence, and therefore it can:

- Answer questions
- Write code
- Translate text
- Summarize documents
- Hold conversations

Some examples of models are: GPT-4, Claude, and Mistral.

## Hello World: Pre-Trained / API Model


#### OpenAI CLI

```
pip3 install openai
```

This is not enough to find the `openai` binary:

```
export PATH="$PATH:$(python3 -c 'import sysconfig; print(sysconfig.get_path("scripts"))')"
```

The following command should then work:

```
openai --help
```

Get the API key from: `https://platform.openai.com/account/api-keys`

Then execute:

```
openai api chat.completions.create -m gpt-3.5-turbo -g user "Hello, world"
```
