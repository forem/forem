$LOAD_PATH.unshift("lib")
require "rspec/core"
require "rspec/retry"

module PGConnectionBadMatcher
  def self.===(exception)
    # Match specifically the statement invalid OR PG::ConnectionBad
    exception.is_a?(ActiveRecord::StatementInvalid) && exception.message.include?("PG::ConnectionBad")
  end
end

RSpec.configure do |config|
  config.verbose_retry = true
  config.display_try_failure_messages = true
  config.default_retry_count = 3
  config.exceptions_to_retry = [PGConnectionBadMatcher]

  config.retry_callback = proc do |ex|
    if ex.exception && PGConnectionBadMatcher === ex.exception
      puts "Retrying due to PG::ConnectionBad."
    end
  end
end

RSpec.describe "Retry Test" do
  it "fails and retries on pg error" do
    if !@failed_once
      @failed_once = true
      raise ActiveRecord::StatementInvalid, "PG::ConnectionBad: PQsocket"
    end
    expect(1).to eq(1)
  end

  it "fails and does not retry normal error" do
    if !@normal_failed_once
      @normal_failed_once = true
      raise "Normal Error"
    end
  end
end
