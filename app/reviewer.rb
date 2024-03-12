class Reviewer
  def create_feedback
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
              description: "The feedback for student submission in markdown."
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
              description: "The feedback for student submission in markdown."
            },
            grades: {
              type: "array",
              description: "The grades to be added to a student submission. This will be an empty array when a submission is rejected",
              items: {
                type: "object",
                properties: {
                  evaluationCriterionId: {
                    type: "string",
                    enum: Submission.new.evaluation_criteria_ids,
                    description: "The Id of evaluation criteria"
                  },
                  grade: {
                    type: "integer",
                    description: "The grade value choosen from allowed grades array for choosen evaluatuion_criterion_id for a submission based on quality"
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
end
