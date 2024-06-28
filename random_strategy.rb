require_relative 'dialogue_strategy'

class RandomStrategy < DialogueStrategy
  attr_reader :cast_members

  def initialize
    @cast_members = Set.new
  end

  def register_intent(cast_member)
    cast_members.add(cast_member)
  end

  def withdraw_intent(cast_member)
    cast_members.delete(cast_member)
  end

  def next
    random_member = cast_members.to_a.sample
    # puts "Random strategy list before delete: #{cast_members.map(&:name)}"
    cast_members.delete(random_member)
    random_member
  end
end
