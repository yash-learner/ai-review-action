FROM ruby:3.1

RUN gem install ruby-openai dotenv pry graphql-client

COPY entrypoint.rb /entrypoint.rb
COPY app/ /app
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
