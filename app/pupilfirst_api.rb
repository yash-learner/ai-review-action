require 'json'
require 'graphql/client'
require 'graphql/client/http'
require_relative 'submission'

class PupilfirstAPI
  ENDPOINT = ENV.fetch('https://www.pupilfirst.school/graphql', "")

  HTTP = GraphQL::Client::HTTP.new(ENDPOINT) do
    def headers(context)
      { "Authorization": "Bearer #{ENV.fetch('REVIEW_BOT_USER_TOKEN')}" }
    end
  end


  Schema = GraphQL::Client.load_schema("./graphql_schema.json")
  Client = GraphQL::Client.new(schema: Schema, execute: HTTP)

  REVIEW_MUTATION = Client.parse <<-'GRAPHQL'
    mutation GradeSubmission(
      $submissionId: ID!
      $grades: [GradeInput!]!
      $checklist: JSON!
      $feedback: String
    ) {
      createGrading(
        submissionId: $submissionId
        grades: $grades
        checklist: $checklist
        feedback: $feedback
      ) {
        success
      }
    }
  GRAPHQL

  def initialize
    @test_mode = ENV.fetch('TEST_MODE') == 'true'
    @submission = Submission.new
  end


  def grade(result)
    valid_statuses = ['success', 'failure']

    variables = {
      submissionId: @submission.id,
      grades: get_grades(@submission.evaluation_criteria, result['status'] == 'success'),
      checklist: @submission.checklist,
      feedback: result['feedback']
    }

    begin
      if @test_mode
        puts "variables: #{variables}"
      else
        if (valid_statuses.include?(result['status']))
          data = Client.query(REVIEW_MUTATION, variables: variables)
          puts data.data
        else
          puts 'Skipped grading'
        end
      end
    rescue StandardError => e
      puts e
    end
  end

  def get_grades(evaluation_criteria, is_passed)
    evaluation_criteria.map do |ec|
      {
        evaluation_criterion_id: ec['id'],
        grade: is_passed ? ec['pass_grade'] : ec['pass_grade'] - 1
      }
    end
  end
end
