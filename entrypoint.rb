require 'openai'
require 'dotenv/load'

OpenAI.configure do |config|
    config.access_token = ENV.fetch("OPENAI_ACCESS_TOKEN")
    # config.organization_id = ENV.fetch("OPENAI_ORGANIZATION_ID", "") # Optional.
end

system_prompt_default = <<-SYSTEM_PROMPT
    You are an automated teacher assistant. You are helping the teacher grade a student's homework.
    The system will always respond with the following json file:
    {
        "status": "passed" or "failed",
        "feedback": "The feedback for the students submission in markdown
    }

    The student's submission is the following:
    #{ENV.fetch("INPUT_PROMPT")}
    SYSTEM_PROMPT

system_prompt = ENV.fetch("INPUT_SYSTEM_PROMPT", system_prompt_default)
user_prompt = ENV.fetch("INPUT_PROMPT")

client = OpenAI::Client.new

response = client.chat(
    parameters: {
        model: "gpt-3.5-turbo", # Required.
        messages: [
            { role: "user", content: system_prompt }
        ],
        temperature: 0.7,
    })

puts response.dig("choices", 0, "message", "content")

puts response
