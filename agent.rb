class Agent
  SPEAK_ACTION = "speak"
  LISTEN_ACTION = "listen"

  MIN_TEMPERATURE = 0.5
  MAX_TEMPERATURE = 1.0

  attr_reader :name, :content, :temperature, :client

  LISTEN_SYSTEM_PROMPT = <<~CONTENT
    Pretend the next message is an inner thought. Respond with exactly the string "YES" or "NO".
    You can say "NO" if you are bored or don't find the topic interesting or if the conversation is wrapping up.
  CONTENT

  LISTEN_USER_PROMPT = <<~CONTENT
    Is there anything you would like to say?"
  CONTENT

  def initialize(name, content)
    @name = name
    @content = content
    @temperature = rand(MIN_TEMPERATURE..MAX_TEMPERATURE)
    @context = [{ role: "system", name: name, content: @content }]
    @client = OpenAI::Client.new
  end

  def listen(speaker, message)
    # Add the new message to the context
    @context << { role: "user", name: speaker, content: message }

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
    # puts "#{name} responded with: #{intent}"
    case intent
    when "YES" then SPEAK_ACTION
    when "NO" then LISTEN_ACTION
    else raise "Invalid response from agent: #{intent}"
    end
  end

  def speak
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
