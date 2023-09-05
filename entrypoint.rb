require 'openai'
require 'dotenv/load'
require 'json'
require 'pry'
require_relative 'app/open_ai_client'
require_relative 'app/submission'
require_relative 'app/pupilfirst_api'

OpenAI.configure do |config|
    config.access_token = ENV.fetch("OPENAI_ACCESS_TOKEN")
    config.organization_id = ENV.fetch("OPENAI_ORGANIZATION_ID", "") # Optional.
end

def generate_response
    @generate_response ||=
    begin
        JSON.parse(OpenAIClient.new.ask)
    rescue => exception
        {
            status: "skip",
            feedback: "Failure message"
        }
    end
end

file_path = "#{ENV['GITHUB_WORKSPACE']}/prompts.json"
puts "PATH"
puts ENV['GITHUB_WORKSPACE']
if File.exist?(file_path)
    puts "Found prompts.json at #{file_path}"
else
    puts "prompts.json not found at #{file_path}"
end

puts JSON.parse(File.read(file_path))


PupilfirstAPI::Grader.new.grade(generate_response)
