class Reviewer
  def initialize(submission)
    @submission = submission
  end

  def create_feedback
    {
      type: "function",
      function: {
        name: "create_feedback",
        description: "Creates feedback for a student submission. These submissions are not graded, only feedback is provided.",
        parameters: {
          type: "object",
          properties: {
            feedback: {
              type: "string",
              description: "The feedback for student submission (in Markdown), should align precisely with the rules and guidelines outlined in the prompt for feedback and evaluation of the submission."
            }
          },
          required: ["feedback"]
        }
      }
    }
  end

  def create_grading
    {
      type: "function",
      function: {
        name: "create_grading",
        description: "Creates grading for a student submission, These submissions should be either accepted or rejected. If accepted, grades should be provided. If rejected, grades should be empty.",
        parameters: {
          type: "object",
          properties: {
            status: {
              type: "string",
              enum: ["accepted", "rejected"]
            },
            feedback: {
              type: "string",
              description: "The feedback for student submission (in Markdown), should align precisely with the rules and guidelines outlined in the prompt for feedback and evaluation of the submission."
            },
            grades: {
              type: "array",
              description: "The grades to be added to a student submission. This should be an empty array when a submission is rejected. When a submission is accepted, this should contain array of objects with evaluationCriterionId and grade.",
              items: {
                type: "object",
                properties: {
                  evaluationCriterionId: {
                    type: "string",
                    enum: @submission.evaluation_criteria_ids,
                    description: "The Id of an evaluation criterion. This should be one of the evaluation criteria Ids of the submission."
                  },
                  grade: {
                    type: "integer",
                    description: "The grade value choosen for an evaluation criterion. This should be between 1 and the max_grade of an evaluation criterion."
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
  end

  def available_tools
    [create_feedback, create_grading]
  end

  def tool_choice
    @submission.evaluation_criteria.any? ? create_grading : create_feedback
  end
end
