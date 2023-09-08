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


@config = YAML.safe_load(File.read('.github/workflows/ci.js.yml'))
puts "config: #{@config}"


puts "ROLE_PROMPT from YAML: #{@config['ROLE_PROMPT']}"
puts "USER_PROMPT from YAML: #{@config['USER_PROMPT']}"
puts "INPUT_DESCRIPTION from YAML: #{@config['INPUT_DESCRIPTION']}"
puts "OUTPUT_DESCRIPTION from YAML: #{@config['OUTPUT_DESCRIPTION']}"
puts "SYSTEM_PROMPT from YAML: #{@config['SYSTEM_PROMPT']}"

PupilfirstAPI::Grader.new.grade(generate_response)
