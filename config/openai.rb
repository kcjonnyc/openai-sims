require 'bundler/setup'
require 'dotenv/load'
require 'openai'

OpenAI.configure do |config|
  config.access_token = ENV['OPENAI_API_KEY']
  config.uri_base = ENV['OPENAI_API_BASE']
  config.log_errors = true
end
