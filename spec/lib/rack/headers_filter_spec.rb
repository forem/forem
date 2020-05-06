require "rails_helper"
require "rack/test"

class EnvRecordingApp
  attr_reader :last_env
  def call(env)
    @last_env = env
    [200, {}, []]
  end
end

describe Rack::HeadersFilter, type: :lib do
  include Rack::Test::Methods

  let(:recording_app) { EnvRecordingApp.new }
  let(:app) { described_class.new(recording_app) }

  it "filters out bad headers" do
    header "Host", "myhost.com"
    header "X-Forwarded-Host", "fake.com"
    get "/"

    expect(recording_app.last_env["HTTP_HOST"]).to eq("myhost.com")
    expect(recording_app.last_env["HTTP_X_FORWARDED_HOST"]).to be_nil
  end

  it "lets other headers through" do
    header "X-Funions", "yum"
    get "/"

    expect(recording_app.last_env["HTTP_X_FUNIONS"]).to eq("yum")
  end
end
