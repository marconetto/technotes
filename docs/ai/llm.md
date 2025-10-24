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

Installs the [OpenAI Python client library](https://github.com/openai/openai-python); which are ysed to interact with OpenAI models (e.g. gpt-3.5, gpt-4, etc).

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

#### Gemini CLI

[Gemini](https://github.com/google-gemini/gemini-cli/blob/main/README.md) is a large language and multimodal model built by Google DeepMind.

It can understand and generate: Text (like chat or code), images, audio, video, and structured data.


```
brew install gemini-cli
```

Starting gemini by selecting authentication method.

```
gemini
```

After this is done, one can ask questions there in an interactive session.

One can also use `-p` (prompt).

```
gemini -p "what was the most common programming language in the 90s"
```

