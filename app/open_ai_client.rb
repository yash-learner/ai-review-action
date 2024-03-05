require "openai"
require "yaml"

class OpenAIClient
  def initialize
    @client = OpenAI::Client.new

    @config = extract_relevant_step_configuration
    @model = @config.fetch("OPEN_AI_MODEL", "gpt-3.5-turbo")
    @temperature = @config.fetch("OPEN_AI_TEMPERATURE", 0.1).to_f
    @system_prompt = @config.fetch("SYSTEM_PROMPT", system_prompt_default)
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

  def create_feedback_function
    {
      type: "function",
      function: {
        name: "create_feedback",
        description: "Creates feedback for a student submission",
        parameters: {
          type: "object",
          properties: {
            feedback: {
              type: "string",
              description: "The feedback to be added to a student submission"
            }
          },
          required: ["feedback"]
        }
      }
    }
  end

  def allowed_grades
    evaluation_criteria = Submission.new.evaluation_criteria
    evaluation_criteria.map do |criteria|
      {evaluation_criteria_id: criteria["id"], allowed_grades: (1..criteria["max_grade"]).to_a}.to_json
    end
  end

  def create_grading_function
    assign_grades = ENV.fetch("ASSIGN_GRADES", "false") == "true"
    if assign_grades
      {
        type: "function",
        function: {
          name: "create_grading",
          description: "Creates grading for a student submission",
          parameters: {
            type: "object",
            properties: {
              status: {
                type: "string",
                enum: ["accepted", "rejected"]
              },
              feedback: {
                type: "string",
                description: "The feedback to be added to a student submission"
              },
              grades: {
                type: "array",
                items: {
                  type: "object",
                  properties: {
                    evaluationCriterionId: {
                      type: "string",
                      enum: Submission.new.evaluation_criteria_ids,
                      grade: {
                        type: "integer",
                        description: "The grade value choosen from available grades for a evaluatuionCriterionID"
                      }
                    },
                    required: ["evaluationCriterionId", "grade"]
                  }
                }
              },
              required: ["status", "feedback", "grades"]
            }
          }
        }
      }
    else
      {
        type: "function",
        function: {
          name: "create_grading",
          description: "Creates grading for a student submission",
          parameters: {
            type: "object",
            properties: {
              status: {
                type: "string",
                enum: ["accepted", "rejected"]
              },
              feedback: {
                type: "string",
                description: "The feedback to be added to a student submission"
              }
            },
            required: ["feedback"]
          }
        }
      }
    end
  end

  def function
    if ENV.fetch("SKIP_GRADING", "false") == "true"
      create_feedback_function
    else
      create_grading_function
    end
  end

  def ask
    puts prompt
    response = @client.chat(
      parameters: {
        model: @model,
        messages: [
          {role: "system", content: prompt}
        ],
        tools: [function],
        temperature: @temperature
      }
    )
    puts response
    # response.dig("choices", 0, "message", "content")
    response.dig("choices", 0, "message", "tool_calls", 0, "function", "arguments")
  end

  def prompt
    @system_prompt
      .gsub("${ROLE_PROMPT}", default_role_prompt)
      .gsub("${INPUT_DESCRIPTION}", default_input_prompt)
      .gsub("${USER_PROMPT}", default_user_prompt)
      .gsub("${SUBMISSION}", "#{Submission.new.checklist}")
      .gsub("${EC_PROMPT}", default_evaluation_criteria_prompt)
      .gsub("${SUBMISSION_EC}", "#{allowed_grades}")
      .gsub("${OUTPUT_DESCRIPTION}", default_output_prompt)
  end

  def system_prompt_default
    <<~SYSTEM_PROMPT
      #{@config.fetch("ROLE_PROMPT", "${ROLE_PROMPT}")}

      #{@config.fetch("INPUT_DESCRIPTION", "${INPUT_DESCRIPTION}")}

      #{@config.fetch("USER_PROMPT", "${USER_PROMPT}")}

      #{@config.fetch("EC_PROMPT", "${EC_PROMPT}")}

      #{@config.fetch("OUTPUT_DESCRIPTION", "${OUTPUT_DESCRIPTION}")}
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
    <<~EC_PROMPT
      The following is array of objects. Each object has two keys
        - evaluation_criteria_id: This key stores the identifier for the evaluation criteria, which can be either a numeric value or a string. This identifier is unique for each set of criteria and is used to reference the specific evaluation criteria being described.
        - llowed_grades": Associated with this key is an array of integers, which represents the set of permissible grades for associated evaluation criterion(evaluation_criteria_id). These grades are predefined and indicate the possible outcomes or ratings that can be assigned based on the evaluation criterion.

        The evaluation_criteria for this submission are:
          ${SUBMISSION_EC}
    EC_PROMPT
  end

  def default_output_prompt
    <<~OUTPUT_PROMPT
      {
          "status": ""accepted" or "rejected"",
          "feedback": "Detailed feedback for the student in markdown format. Aim for a human-like explanation as much as possible."
      }

      If the student submission is not related to question, share generic feedback.
    OUTPUT_PROMPT
  end
end
