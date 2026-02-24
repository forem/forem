require "rails_helper"

RSpec.configure do |config|
  config.default_retry_count = 3

  module PGConnectionBadMatcher
    def self.===(exception)
      # Match specifically the statement invalid OR PG::ConnectionBad
      exception.is_a?(ActiveRecord::StatementInvalid) && exception.message.include?("PG::ConnectionBad")
    end
  end

  config.exceptions_to_retry = [PGConnectionBadMatcher]

  # To solve the cascading failures across the whole file, we need to reconnect
  config.retry_callback = proc do |ex|
    if ex.exception && PGConnectionBadMatcher === ex.exception
      puts "Retrying due to PG::ConnectionBad. Reconnecting to the database."
      ActiveRecord::Base.connection_pool.disconnect!
    end
  end
end

RSpec.describe "PG Connection Failure Test" do
  it "fails with PG::ConnectionBad but retries" do
    if !@failed_once
      @failed_once = true
      raise ActiveRecord::StatementInvalid, "PG::ConnectionBad: PQsocket() can't get socket descriptor"
    end
    expect(1).to eq(1)
  end

  it "fails with a normal error and does not retry" do
    if !@normal_failed_once
      @normal_failed_once = true
      raise "Normal Error"
    end
  end
end
