require "openai"
require "dotenv/load"
require "json"
require "pry"
require_relative "app/open_ai_client"
require_relative "app/submission"
require_relative "app/pupilfirst_api"

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

if ENV.fetch("SKIP_GRADING", "false") == "true"
  PupilfirstAPI::Grader.new.add_feedback(generate_response)
else
  puts "Grading..."
  PupilfirstAPI::Grader.new.grade(generate_response)
end
