require_relative 'config'
require_relative 'agent'
require_relative 'random_strategy'

client = OpenAI::Client.new

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
    "content": "You are a young high-school math teacher with a crush on your colleague. You are constantly embaressed having to face him in front of your students."
  }]

  Request ID: #{SecureRandom.uuid}
CONTENT

AGENT_ADDITIONAL_RULES = <<~CONTENT
  Rules:
  - You are having a conversation in a group of #{NUM_CAST_MEMBERS}.
  - Do not respond with more than one paragraph at a time.
CONTENT

def create_cast(client)
  response = client.chat(
    parameters: {
      model: 'gpt-4o',
      messages: [{ role: "user", content: CREATE_CAST_PROMPT }],
      temperature: 1.4, # Higher temperature means the model will take more risks but come up with more creative names and characters
    }
  )

  json_string = response.dig("choices", 0, "message", "content")
  json_cast_members = JSON.parse(json_string)
  json_cast_members.map do |cast_member|
    puts "Name: #{cast_member["name"]}\nDescription: #{cast_member["content"]}\n\n"
    Agent.new(cast_member["name"], cast_member["content"] + "\n" + AGENT_ADDITIONAL_RULES)
  end
end

cast_members = create_cast(client)
dialogue_strategy = RandomStrategy.new

# Start the conversation by adding the facilitator to the dialogue strategy
dialogue_strategy.register_intent(cast_members.first)

while (speaker = dialogue_strategy.next)
  message = speaker.speak
  puts "#{speaker.name}: #{message}\n\n"

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
