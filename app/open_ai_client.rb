require "openai"
require "yaml"
require "json"

class OpenAIClient
  def initialize
    @client = OpenAI::Client.new

    @config = extract_relevant_step_configuration
    @model = @config.fetch("OPEN_AI_MODEL", "gpt-3.5-turbo")
    @temperature = @config.fetch("OPEN_AI_TEMPERATURE", 0.1).to_f
    @system_prompt = @config.fetch("SYSTEM_PROMPT", system_prompt_default)

    @submission = Submission.new
    @reviewer = Reviewer.new(@submission)
  end

  def extract_relevant_step_configuration
    # Load workflow YAML file from the path specified in the environment variable or the default path.
    file_path = ENV.fetch("WORKFLOW_FILE_PATH", "./.github/workflows/ci.js.yml")

    # Find the job step that uses 'pupilfirst/ai-review-action' or has an ID containing 'ai-review'.
    content = YAML.safe_load_file(file_path)

    @config = content.dig("jobs", "test", "steps").find do |step|
      (step["uses"]&.include?("pupilfirst/ai-review-action") || step["id"]&.include?("ai-review"))
    end["env"]

    if @config.nil?
      p content

      raise "Could not read configuration from environment variables. Please check the workflow file."
    end

    @config
  end

  def ask
    puts prompt
    response = @client.chat(
      parameters: {
        model: @model,
        messages: [
          {role: "system", content: prompt}
        ],
        tools: @reviewer.available_tools,
        tool_choice: @reviewer.tool_choice,
        temperature: @temperature
      }
    )
    puts response

    message = response.dig("choices", 0, "message")
    if message["role"] == "assistant" && message["tool_calls"]
      message["tool_calls"].each do |tool_call|
        function_name = tool_call.dig("function", "name")
        args_json = tool_call.dig("function", "arguments")
        begin
          args = JSON.parse(args_json, symbolize_names: true)
          return {function_name: function_name, args: args}
        rescue JSON::ParserError => e
          puts "Error parsing JSON arguments: #{e.message}"
        end
      end
    else
      {function_name: "errored", args: {}}
    end
  end

  def prompt
    @system_prompt
      .gsub("${ROLE_PROMPT}", default_role_prompt)
      .gsub("${INPUT_DESCRIPTION}", default_input_prompt)
      .gsub("${USER_PROMPT}", default_user_prompt)
      .gsub("${SUBMISSION}", "#{@submission.checklist}")
      .gsub("${EC_PROMPT}", default_evaluation_criteria_prompt)
      .gsub("${SUBMISSION_EC}", "#{@submission.evaluation_criteria}")
  end

  def system_prompt_default
    <<~SYSTEM_PROMPT
      #{@config.fetch("ROLE_PROMPT", "${ROLE_PROMPT}")}

      #{@config.fetch("INPUT_DESCRIPTION", "${INPUT_DESCRIPTION}")}

      #{@config.fetch("USER_PROMPT", "${USER_PROMPT}")}

      #{@config.fetch("EC_PROMPT", "${EC_PROMPT}")}
    SYSTEM_PROMPT
  end

  def default_role_prompt
    <<~ROLE_PROMPT
      You are an advanced Teaching Assistant AI. Your task involves reviewing and providing feedback on student submissions.
    ROLE_PROMPT
  end

  def default_user_prompt
    <<~USER_PROMPT
      The student's submission will be as follows:
      ${SUBMISSION}
    USER_PROMPT
  end

  def default_input_prompt
    <<~INPUT_PROMPT
      The student's submissions will be an array of objects following the provided schema:

      {
        "kind": "The type of answer - can be shortText, longText, link, files, or multiChoice",
        "title": "The question that was asked of the student",
        "result": "The student's response",
        "status": "Field for internal use; ignore this field during your review"
      }

    INPUT_PROMPT
  end

  def default_evaluation_criteria_prompt
    if @submission.evaluation_criteria.any?
      <<~EC_PROMPT
        The following describes an array of objects where each object represents an evaluation criterion for a submission. Each criterion object includes the following key attributes:
          - id: This key stores the identifier for the evaluation criteria, which can be either a numeric value or a string.
          - name: The name of the evaluation criterion, describing the aspect of the submission it assesses.
          - max_grade: The maximum grade that can be assigned for this criterion.
          - grade_labels: An array of objects, each containing a 'grade' and a 'label'. 'grade' is an integer representing a possible grade for the criterion, and 'label' is a description of what this grade signifies.

          Below is the structured representation of the evaluation criteria for the current submission:
            ${SUBMISSION_EC}
      EC_PROMPT
    else
      ""
    end
  end
end
