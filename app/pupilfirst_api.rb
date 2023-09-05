require 'json'
require 'graphql/client'
require 'graphql/client/http'
require_relative 'submission'

# Pupilfirst API example wrapper
module PupilfirstAPI

  module API
    HTTP = GraphQL::Client::HTTP.new(ENV.fetch('REVIEW_END_POINT')) do
      def headers(_context)
        { "Authorization": "Bearer #{ENV.fetch('REVIEW_BOT_USER_TOKEN')}" }
      end
    end

    Schema = GraphQL::Client.load_schema('./app/graphql_schema.json')

    Client = GraphQL::Client.new(schema: Schema, execute: HTTP)
  end

  GradeMutation = API::Client.parse <<-'GRAPHQL'
    mutation($submissionId: ID!, $grades: [GradeInput!]!, $checklist: JSON!, $feedback: String) {
      createGrading(submissionId: $submissionId, grades: $grades, checklist: $checklist, feedback: $feedback) {
        success
      }
    }
  GRAPHQL

  class Grader
    def initialize(submission = Submission.new)
      @submission = submission
      @test_mode = ENV.fetch('TEST_MODE', 'false') == 'true'
    end

    def grade(result)
      return puts 'Skipped grading' unless valid_status?(result['status'])

      variables = {
        submissionId: @submission.id,
        grades: grades_based_on(result['status']),
        checklist: @submission.checklist,
        feedback: result['feedback']
      }

      puts "variables: #{variables}" if @test_mode

      create_grading(variables) unless @test_mode
    rescue StandardError => e
      puts e
    end

    private

    def valid_status?(status)
      %w[passed failed].include?(status)
    end

    def grades_based_on(status)
      @submission.evaluation_criteria.map do |criteria|
        {
          evaluationCriterionId: criteria['id'],
          grade: grade_for(criteria, status)
        }
      end
    end

    def grade_for(criteria, status)
      status == 'passed' ? criteria['pass_grade'] : criteria['pass_grade'] - 1
    end

    def create_grading(variables)
      result = API::Client.query(GradeMutation, variables: variables)
      if result.data
        puts result.data.create_grading.success
      else
        puts result.errors["data"]
      end
    end
  end
end
