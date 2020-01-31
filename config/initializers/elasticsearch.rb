require "elasticsearch"

SearchClient = Elasticsearch::Client.new(
  url: ApplicationConfig["ELASTICSEARCH_URL"],
  retry_on_failure: 5,
  request_timeout: 30,
  adapter: :typhoeus,
  log: Rails.env.development?,
)
