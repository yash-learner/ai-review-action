FROM ruby:3.1

RUN gem install ruby-openai dotenv pry graphql-client

COPY entrypoint.rb /entrypoint.rb
COPY app/ /app
COPY graphql_schema.json /graphql_schema.json
COPY submission.json /submission.json
# COPY entrypoint.sh /entrypoint.sh

# RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/usr/local/bin/ruby", "/entrypoint.rb"]
