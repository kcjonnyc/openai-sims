require_relative 'config/openai'
require_relative 'logger_service'

class Agent
  SPEAK_ACTION = "speak"
  LISTEN_ACTION = "listen"

  MIN_TEMPERATURE = 0.5
  MAX_TEMPERATURE = 1.0

  attr_reader :name, :description, :prompt, :temperature, :client

  LISTEN_SYSTEM_PROMPT = <<~CONTENT
    The next message is an inner thought. Respond with one of the options ["SPEAK", "LISTEN"].
    You must respond with exactly one of the options, without saying anything else.

    Say "SPEAK" if:
    - You want to continue the conversation; the conversation will end if all participants say "LISTEN".
    - You have something new to say or a new idea to introduce.
    - You want to respond to a question or comment.

    Say "LISTEN" if:
    - You are bored or don't find the topic interesting.
    - The conversation is wrapping up.
    - You have nothing new to say.
    - The conversation has been going on for a while; you get tired the longer the conversation goes on.
  CONTENT

  LISTEN_USER_PROMPT = <<~CONTENT
    What would you like to do next?
  CONTENT

  def initialize(name:, description:, prompt:)
    @name = name
    @description = description
    @prompt = prompt
    @temperature = rand(MIN_TEMPERATURE..MAX_TEMPERATURE)
    @context = [{ role: "system", name: name, content: prompt }]
    @client = OpenAI::Client.new
  end

  def listen(speaker, message)
    # Add the new message to the context
    LoggerService.logger.debug("[#{self.class}][listen] #{name} heard message from #{speaker}, making a request to OpenAI to determine next action")
    @context << { role: "user", name: speaker, content: message }

    # Make a request to OpenAI to determine the agent's next action
    response = client.chat(
      parameters: {
        model: 'gpt-4o',
        # We need to ask this agent if they would like to register their intention to speak; however, this information does not need to be added to the context
        messages: @context + [
          { role: "system", name: name, content: LISTEN_SYSTEM_PROMPT },
          { role: "user", content: LISTEN_USER_PROMPT }
        ],
        temperature: temperature,
      }
    )
    intent = response.dig("choices", 0, "message", "content")
    LoggerService.logger.debug("[#{self.class}][listen] Response from OpenAI: #{intent}")
    case intent
    when "SPEAK" then SPEAK_ACTION
    when "LISTEN" then LISTEN_ACTION
    else raise "Invalid response from agent: #{intent}"
    end
  end

  def speak
    LoggerService.logger.debug("[#{self.class}][speak] #{name} is speaking")
    response = client.chat(
      parameters: {
        model: 'gpt-4o',
        messages: @context,
        temperature: temperature,
      }
    )
    message = response.dig("choices", 0, "message", "content")
    @context << { role: "assistant", name: name, content: message}
    message
  end
end
