require 'openai'

class OpenAIClient
  def initialize
    @client = OpenAI::Client.new
    @model = ENV.fetch('OPEN_AI_MODEL', "gpt-3.5-turbo")
    @temperature = ENV.fetch('OPEN_AI_TEMPERATURE', 0.1)
    @system_prompt = ENV.fetch('SYSTEM_PROMPT', system_prompt_default)
    @user_prompt = ENV.fetch('USER_PROMPT')
  end

  def ask
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
    .gsub("${SUBMISSION}", Submission.new.checklist)
    .gsub("${INPUT_DESCRIPTION}", default_input_prompt)
    .gsub("${OUTPUT_DESCRIPTION}", default_output_prompt)
    .gsub("${ROLE_PROMPT}", default_role_prompt)
    .gsub("${USER_PROMPT}", default_user_prompt)

  def system_prompt_default
<<-SYSTEM_PROMPT
#{ENV.fetch("ROLE_PROMPT", "${ROLE_PROMPT}")}

#{ENV.fetch("INPUT_DESCRIPTION", "${INPUT_DESCRIPTION}")}

#{ENV.fetch("USER_PROMPT", "${USER_PROMPT}")}

#{ENV.fetch("OUTPUT_DESCRIPTION", "${OUTPUT_DESCRIPTION}")}
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
    "status": "\"success\" or \"failure\"",
    "feedback": "Detailed feedback for the student in markdown format. Aim for a human-like explanation as much as possible"
}
```
If the student submission is not related to question share a genric feedback
OUTPUT_PROMPT
  end
end
