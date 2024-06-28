require_relative 'agent'
require_relative 'config/openai'
require_relative 'logger_service'
require_relative 'random_strategy'

class Simulator
  MIN_CAST_MEMBERS = 2
  MAX_CAST_MEMBERS = 5
  NUM_CAST_MEMBERS = rand(MIN_CAST_MEMBERS..MAX_CAST_MEMBERS)

  # This prompt contains a UUID to avoid cached results, it is not required if calling OpenAI API diectly
  CREATE_CAST_PROMPT = <<~CONTENT
    Generate #{NUM_CAST_MEMBERS} characters that can be used as system prompts to GPT.

    Rules:
    - The response must be valid JSON, without any formatting.
    - Each character should have two attributes: name and content.
    - The name attribute must be a first name and have no special characters.
    - The content attribute is used to describe the character and their personality.
    - Be creative with the characters and their personalities.

    Example:
    [{
      "name": "Kate",
      "content": "You are a 26 year old high-school math teacher with a crush on your colleague. You are constantly embaressed having to face him in front of your students."
    }]

    Request ID: #{SecureRandom.uuid}
  CONTENT

  AGENT_ADDITIONAL_RULES = <<~CONTENT
    Rules:
    - You are having a conversation in a group of #{NUM_CAST_MEMBERS}.
    - Do not respond with more than one paragraph at a time.
    - Speak naturally as a human and do not sound robotic.
    - If the conversation is becoming repetitive, change the topic or end the conversation.
    - Do not respond in the form of a script.
  CONTENT

  attr_reader :client, :dialogue_strategy

  def initialize
    @client = OpenAI::Client.new
    @dialogue_strategy = RandomStrategy.new
  end

  def create_cast
    LoggerService.logger.debug("[#{self.class}][create_cast] Making request to OpenAI using prompt: #{CREATE_CAST_PROMPT}")
    response = client.chat(
      parameters: {
        model: 'gpt-4o',
        messages: [{ role: "user", content: CREATE_CAST_PROMPT }],
        temperature: 1.4, # Higher temperature means the model will take more risks but come up with more creative names and characters
      }
    )
    json_string = response.dig("choices", 0, "message", "content")
    LoggerService.logger.debug("[#{self.class}][create_cast] Response from OpenAI: #{json_string}")
    json_cast_members = JSON.parse(json_string)
    json_cast_members.map do |cast_member|
      Agent.new(
        name: cast_member["name"],
        description: cast_member["content"],
        prompt: "#{cast_member["content"]}\n#{AGENT_ADDITIONAL_RULES}",
      )
    end
  end

  def print_cast(cast_members)
    cast_members.each do |cast_member|
      LoggerService.logger.info("Name: #{cast_member.name}")
      LoggerService.logger.info("Description: #{cast_member.description}\n")
    end
  end

  def run_simulation(cast_members)
    # Start the conversation by adding the facilitator to the dialogue strategy
    dialogue_strategy.register_intent(cast_members.first)

    # Continue until there is no one left wanting to speak
    while (speaker = dialogue_strategy.next)
      message = speaker.speak
      LoggerService.logger.info("#{speaker.name}: #{message}\n")

      # Notify all other agents of the message
      cast_members.each do |cast_member|
        unless cast_member == speaker
          next_action = cast_member.listen(speaker.name, message)
          if next_action == Agent::SPEAK_ACTION
            dialogue_strategy.register_intent(cast_member)
          else
            dialogue_strategy.withdraw_intent(cast_member)
          end
        end
      end
    end
  end
end
