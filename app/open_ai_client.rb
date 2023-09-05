require 'openai'
require 'json'

class OpenAIClient
  def initialize
    @client = OpenAI::Client.new
    @model = ENV.fetch('OPEN_AI_MODEL', "gpt-3.5-turbo")
    @temperature = ENV.fetch('OPEN_AI_TEMPERATURE', 0.1)

    prompts = JSON.parse(File.read('prompts.json'))
    @role_prompt = prompts.fetch("ROLE_PROMPT", default_role_prompt)
    @user_prompt = prompts.fetch("USER_PROMPT", default_user_prompt)
    @input_description = prompts.fetch("INPUT_DESCRIPTION", default_input_prompt)
    @output_description = prompts.fetch("OUTPUT_DESCRIPTION", default_output_prompt)
    @system_prompt = prompts.fetch('SYSTEM_PROMPT', system_prompt_default)

    puts "Prompts: #{prompts.inspect}"
    puts "System prompt: #{@system_prompt}"
  end

  def ask
    puts "Prompt: #{prompt}"
    puts prompt
    response = @client.chat(
        parameters: {
            model: @model,
            messages: [
                { role: "system", content: prompt }
            ],
            temperature: @temperature,
        })
    puts response
    response.dig("choices", 0, "message", "content")
  end

  def replace_placeholder(text, placeholder, value)
    text.gsub("${#{placeholder}}", value)
  end

  def prompt
    @system_prompt
    .gsub("${SUBMISSION}", "#{Submission.new.checklist}")
  end

  def system_prompt_default
<<-SYSTEM_PROMPT
#{@role_prompt}

#{@input_description}

#{@user_prompt}

#{@output_description}
SYSTEM_PROMPT
  end

  def default_role_prompt
<<-ROLE_PROMPT
You are an advanced Teaching Assistant AI. Your task involves reviewing and providing feedback on student submissions.
ROLE_PROMPT
  end

  def default_user_prompt
<<-USER_PROMPT
The student's submission will be as follows:
${SUBMISSION}
USER_PROMPT
  end

  def default_input_prompt
<<-INPUT_PROMPT
The student's submissions will be an array of objects following the provided schema:

```json
{
  "kind": "The type of answer - can be shortText, longText, link, files, or multiChoice",
  "title": "The question that was asked of the student",
  "result": "The student's response",
  "status": "Field for internal use; ignore this field during your review"
}
```
INPUT_PROMPT
  end

  def default_output_prompt
<<-OUTPUT_PROMPT
Please provide your response in the following JSON format (adhere to the format strictly):

```json
{
    "status": "\"passed\" or \"failed\"",
    "feedback": "Detailed feedback for the student in markdown format. Aim for a human-like explanation as much as possible"
}
```
If the student submission is not related to question share a genric feedback
OUTPUT_PROMPT
  end
end
