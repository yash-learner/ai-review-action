class Reviewer
  def review
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

  def reject
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
              description: "The feedback to be added to a student submission"
            }
          },
          required: ["feedback"]
        }
      }
    }
  end

  def dynamic_grading
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

  def avilable_actions
    [review, reject, create_feedback, dynamic_grading]
  end
end
