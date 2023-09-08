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


github_action_path = ENV['GITHUB_ACTION_PATH'] || ''
workflow_file_path = ENV.fetch('WORKFLOW_FILE_PATH', '.github/workflows/ci.js.yml')

content = YAML.safe_load(File.read(File.join(github_action_path, workflow_file_path)))
@config = content.dig('jobs', 'test', 'steps').find { |step| step['id'] == 'ai-review' }&.fetch('with', {})
puts "content: #{content}"

PupilfirstAPI::Grader.new.grade(generate_response)
