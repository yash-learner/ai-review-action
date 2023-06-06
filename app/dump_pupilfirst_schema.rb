require "graphql/client"
require "graphql/client/http"
require_relative "pupilfirst_api"

GraphQL::Client.dump_schema(PupilfirstAPI::HTTP, "./schema.json")
