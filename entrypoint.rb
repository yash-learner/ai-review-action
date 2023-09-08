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


if File.exist?('../.github/workflows/test.yml')
    puts "The file exists!"
else
    puts "The file does not exist!"
end


content = YAML.safe_load(File.read(ENV.fetch("WORKFLOW_FILE_PATH", ".github/workflows/ci.js.yml")))
puts "content: #{content}"

PupilfirstAPI::Grader.new.grade(generate_response)
