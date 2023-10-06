require 'openai'
require 'yaml'

class OpenAIClient
  def initialize
    @client = OpenAI::Client.new

    @config = extract_relevant_step_configuration
    @model = @config.fetch('OPEN_AI_MODEL', "gpt-3.5-turbo")
    @temperature = @config.fetch('OPEN_AI_TEMPERATURE', 0.1).to_f
    @system_prompt = @config.fetch('SYSTEM_PROMPT', system_prompt_default)
  end

  def extract_relevant_step_configuration
    # Load workflow YAML file from the path specified in the environment variable or the default path.
    file_path = ENV.fetch('WORKFLOW_FILE_PATH', './.github/workflows/ci.js.yml')

    # Find the job step that uses 'pupilfirst/ai-review-action' or has an ID containing 'ai-review'.
    content = YAML.safe_load(File.read(file_path))

    @config = content.dig('jobs', 'test', 'steps').find do |step|
      ( step['uses']&.include?('pupilfirst/ai-review-action') || step['id']&.include?('ai-review') )
    end['env']

    if @config.nil?
      p content

      raise 'Could not read configuration from environment variables. Please check the workflow file.'
    end

    @config
  end

  def ask
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

  def prompt
    @system_prompt
    .gsub("${ROLE_PROMPT}", default_role_prompt)
    .gsub("${INPUT_DESCRIPTION}", default_input_prompt)
    .gsub("${USER_PROMPT}", default_user_prompt)
    .gsub("${SUBMISSION}", "#{Submission.new.checklist}")
    .gsub("${OUTPUT_DESCRIPTION}", default_output_prompt)
  end

  def system_prompt_default
<<-SYSTEM_PROMPT
#{@config.fetch("ROLE_PROMPT", "${ROLE_PROMPT}")}

#{@config.fetch("INPUT_DESCRIPTION", "${INPUT_DESCRIPTION}")}

#{@config.fetch("USER_PROMPT", "${USER_PROMPT}")}

#{@config.fetch("OUTPUT_DESCRIPTION", "${OUTPUT_DESCRIPTION}")}
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
Please provide your response in the following JSON format. Adhere to the format strictly and escape all line-breaks within strings using \\\\n.

```json
{
    "status": "\"passed\" or \"failed\"",
    "feedback": "Detailed feedback for the student in markdown format. Aim for a human-like explanation as much as possible."
}
```

If the student submission is not related to question, share generic feedback.
OUTPUT_PROMPT
  end
end
