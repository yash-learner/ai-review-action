FROM ruby:3.1

RUN gem install ruby-openai dotenv pry graphql-client

COPY entrypoint.rb /entrypoint.rb

ENTRYPOINT ["/usr/local/bin/ruby", "/entrypoint.rb"]
