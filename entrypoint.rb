require "openai"
require "dotenv/load"
require "pry"
require_relative "app/open_ai_client"
require_relative "app/submission"
require_relative "app/pupilfirst_api"
require_relative "app/reviewer"

OpenAI.configure do |config|
  config.access_token = ENV.fetch("OPENAI_ACCESS_TOKEN")
  config.organization_id = ENV.fetch("OPENAI_ORGANIZATION_ID", "") # Optional.
end

def generate_response
  attempts = 0

  begin
    attempts += 1
    response = OpenAIClient.new.ask

    case response[:function_name]
    when "create_grading"
      PupilfirstAPI::Grader.new.grade(response[:args])
    when "create_feedback"
      PupilfirstAPI::Grader.new.add_feedback(response[:args])
    else
      raise "Unknown response from OpenAI: #{response}"
    end
  rescue => e
    puts "Attempt #{attempts} failed due to error: #{e.message}"
    if attempts <= 1
      puts "Retrying... Attempt #{attempts + 1}"
      retry
    else
      puts "Max attempts reached. Exiting."
      raise e
    end
  end
end

generate_response
