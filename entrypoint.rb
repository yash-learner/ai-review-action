require 'openai'
require 'dotenv/load'
require 'json'
require 'pry'
require_relative 'app/open_ai_client'
require_relative 'app/submission'

OpenAI.configure do |config|
    config.access_token = ENV.fetch("OPENAI_ACCESS_TOKEN")
    # config.organization_id = ENV.fetch("OPENAI_ORGANIZATION_ID", "") # Optional.
end

def generate_response
    @generate_response ||=
    begin
        JSON.parse(OpenAIClient.new.ask)
    rescue => exception
        {
            status: "failed",
            feedback: "Failure message"
        }
    end
end

File.write('/tmp/output.json', generate_response.to_json)
