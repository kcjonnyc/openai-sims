require 'logger'
require 'colorize'

class ColorfulFormatter < Logger::Formatter
  def call(severity, time, progname, message)
    color = case severity
            when "DEBUG" then :light_blue
            else :default
            end
    "#{message}\n".colorize(color)
  end
end

class LoggerService
  def self.logger
    @logger = Logger.new(STDOUT).tap do |logger|
      logger.level = Logger::INFO
      logger.formatter = ColorfulFormatter.new
    end
  end
end
