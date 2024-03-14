require "json"
require "graphql/client"
require "graphql/client/http"
require_relative "submission"

# Pupilfirst API example wrapper
module PupilfirstAPI
  module API
    HTTP = GraphQL::Client::HTTP.new(ENV.fetch("REVIEW_END_POINT")) do
      def headers(_context)
        {Authorization: "Bearer #{ENV.fetch("REVIEW_BOT_USER_TOKEN")}"}
      end
    end

    Schema = GraphQL::Client.load_schema("/app/graphql_schema.json")

    Client = GraphQL::Client.new(schema: Schema, execute: HTTP)
  end

  GradeMutation = API::Client.parse <<-GRAPHQL
    mutation($submissionId: ID!, $grades: [GradeInput!], $checklist: JSON!, $feedback: String) {
      createGrading(submissionId: $submissionId, grades: $grades, checklist: $checklist, feedback: $feedback) {
        success
      }
    }
  GRAPHQL

  CreateFeedbackMutation = API::Client.parse <<-GRAPHQL
    mutation($submissionId: ID!, $feedback: String!) {
      createFeedback(submissionId: $submissionId, feedback: $feedback) {
        success
      }
    }
  GRAPHQL

  class Grader
    def initialize(submission = Submission.new)
      @submission = submission
      @test_mode = ENV.fetch("TEST_MODE", "false") == "true"
    end

    def grade(result)
      return puts "Unknown status: #{result[:status].inspect}. Skipping grading..." unless valid_status?(result[:status])

      variables = {
        submissionId: @submission.id,
        checklist: @submission.checklist,
        feedback: result[:feedback]
      }

      # We can use the value of the result[:grades] but we are using following method to handle the case when model hallucinates the grades for a rejected submission.
      grades = grades_based_on(result)

      variables[:grades] = grades if grades.length > 0

      log_variables(variables) if @test_mode
      create_grading(variables) unless @test_mode
    rescue => e
      handle_error(e)
    end

    def add_feedback(result)
      variables = {
        submissionId: @submission.id,
        feedback: result[:feedback]
      }

      log_variables(variables) if @test_mode
      create_feedback(variables) unless @test_mode
    rescue => e
      handle_error(e)
    end

    private

    def valid_status?(status)
      %w[accepted rejected].include?(status)
    end

    def grades_based_on(result)
      if result[:status] == "accepted"
        result[:grades]
      else
        []
      end
    end

    def log_variables(variables)
      puts "[TEST MODE] Variables: #{variables.inspect}"
    end

    def create_grading(variables)
      result = API::Client.query(GradeMutation, variables: variables)

      if result.data
        puts result.data.create_grading.success
      else
        puts result.errors["data"]
      end
    end

    def create_feedback(variables)
      result = API::Client.query(CreateFeedbackMutation, variables: variables)

      if result.data
        puts result.data.create_feedback.success
      else
        puts result.errors["data"]
      end
    end

    def handle_error(e)
      puts "An unexpected error occurred. Skipping grading..."
      puts "Error class/type: #{e.class}"
      puts "Error message: #{e.message}"
      puts "Backtrace: #{e.backtrace[0..5].join("\n")}"
    end
  end
end
