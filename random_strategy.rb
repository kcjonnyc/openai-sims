require_relative 'dialogue_strategy'
require_relative 'logger_service'

class RandomStrategy < DialogueStrategy
  attr_reader :cast_members

  def initialize
    @cast_members = Set.new
  end

  def register_intent(cast_member)
    LoggerService.logger.debug("[#{self.class}][register_intent] Registering intent for #{cast_member.name}")
    cast_members.add(cast_member)
    LoggerService.logger.debug("[#{self.class}][register_intent] Updated list: #{cast_members.map(&:name)}")
  end

  def withdraw_intent(cast_member)
    LoggerService.logger.debug("[#{self.class}][withdraw_intent] Withdrawing intent for #{cast_member.name}")
    cast_members.delete(cast_member)
    LoggerService.logger.debug("[#{self.class}][withdraw_intent] Updated list: #{cast_members.map(&:name)}")
  end

  def next
    random_member = cast_members.to_a.sample
    return if random_member.nil?

    LoggerService.logger.debug("[#{self.class}][next] Next is #{random_member.name}")
    cast_members.delete(random_member)
    LoggerService.logger.debug("[#{self.class}][withdraw_intent] Updated list: #{cast_members.map(&:name)}")
    random_member
  end
end
