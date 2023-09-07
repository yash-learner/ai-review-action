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

@config = YAML.safe_load(File.read("#{ENV['GITHUB_WORKSPACE']}/config.yml"))
puts "config: #{@config}"

PupilfirstAPI::Grader.new.grade(generate_response)
