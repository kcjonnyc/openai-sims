# OpenAI Sims

This is a simulation with multiple GPT agents chatting with each other. With more work, maybe it could even be more interactive like a Sims game. GPT is used to create characters for a conversation. An agent is instantiated for each character and uses GPT independently.

## Instructions

Add a `.env` file with the following:
```
OPENAI_API_KEY=<openai_api_key>
OPENAI_API_BASE=<openai_api_uri>
```

Run the commands:
```zsh
bundle install
ruby main.rb
```