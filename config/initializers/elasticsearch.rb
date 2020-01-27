require "elasticsearch"

Search = Elasticsearch::Client.new(
  url: ApplicationConfig["ELASTICSEARCH_URL"],
  retry_on_failure: 5,
  request_timeout: 30,
)
