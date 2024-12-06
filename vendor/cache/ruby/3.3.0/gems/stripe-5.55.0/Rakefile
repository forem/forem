# frozen_string_literal: true

require "rake/testtask"
require "rubocop/rake_task"

task default: %i[test rubocop]

Rake::TestTask.new do |t|
  t.pattern = "./test/**/*_test.rb"
end

RuboCop::RakeTask.new

desc "Update bundled certs"
task :update_certs do
  require "net/http"
  require "uri"

  fetch_file "https://curl.haxx.se/ca/cacert.pem",
             ::File.expand_path("../lib/data/ca-certificates.crt", __FILE__)
end

#
# helpers
#

def fetch_file(uri, dest)
  ::File.open(dest, "w") do |file|
    resp = Net::HTTP.get_response(URI.parse(uri))
    unless resp.code.to_i == 200
      abort("bad response when fetching: #{uri}\n" \
        "Status #{resp.code}: #{resp.body}")
    end
    file.write(resp.body)
    puts "Successfully fetched: #{uri}"
  end
end
