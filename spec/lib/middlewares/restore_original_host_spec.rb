require "rails_helper"

RSpec.describe Middlewares::RestoreOriginalHost, type: :middleware do
  let(:app) { ->(env) { [200, env, "OK"] } }
  let(:middleware) { described_class.new(app) }

  context "when HTTP_FASTLY_ORIG_HOST is present" do
    it "overrides HTTP_HOST with the value of HTTP_FASTLY_ORIG_HOST" do
      env = {
        "HTTP_HOST" => "practicaldev.herokuapp.com",
        "HTTP_FASTLY_ORIG_HOST" => "mlh.forem.wtf"
      }
      _status, result_env, _body = middleware.call(env)

      expect(result_env["HTTP_HOST"]).to eq("mlh.forem.wtf")
    end
  end

  context "when HTTP_X_FORWARDED_HOST is present and HTTP_FASTLY_ORIG_HOST is absent" do
    before do
      allow(Rails.env).to receive(:production?).and_return(false)
    end

    it "overrides HTTP_HOST with the value of HTTP_X_FORWARDED_HOST" do
      env = {
        "HTTP_HOST" => "practicaldev.herokuapp.com",
        "HTTP_X_FORWARDED_HOST" => "mlh.forem.wtf"
      }
      _status, result_env, _body = middleware.call(env)

      expect(result_env["HTTP_HOST"]).to eq("mlh.forem.wtf")
    end

    it "takes the first host when HTTP_X_FORWARDED_HOST has comma-separated values" do
      env = {
        "HTTP_HOST" => "practicaldev.herokuapp.com",
        "HTTP_X_FORWARDED_HOST" => "mlh.forem.wtf, practicaldev.herokuapp.com"
      }
      _status, result_env, _body = middleware.call(env)

      expect(result_env["HTTP_HOST"]).to eq("mlh.forem.wtf")
    end
  end

  context "when HTTP_X_FORWARDED_HOST is present and environment is production" do
    before do
      allow(Rails.env).to receive(:production?).and_return(true)
    end

    it "overrides HTTP_HOST with the value of HTTP_X_FORWARDED_HOST" do
      env = {
        "HTTP_HOST" => "practicaldev.herokuapp.com",
        "HTTP_X_FORWARDED_HOST" => "mlh.forem.wtf"
      }
      _status, result_env, _body = middleware.call(env)

      expect(result_env["HTTP_HOST"]).to eq("mlh.forem.wtf")
    end
  end

  context "when both HTTP_FASTLY_ORIG_HOST and HTTP_X_FORWARDED_HOST are present" do
    it "prioritizes HTTP_FASTLY_ORIG_HOST" do
      env = {
        "HTTP_HOST" => "practicaldev.herokuapp.com",
        "HTTP_FASTLY_ORIG_HOST" => "fastly-orig.com",
        "HTTP_X_FORWARDED_HOST" => "forwarded.com"
      }
      _status, result_env, _body = middleware.call(env)

      expect(result_env["HTTP_HOST"]).to eq("fastly-orig.com")
    end
  end

  context "when neither HTTP_FASTLY_ORIG_HOST nor HTTP_X_FORWARDED_HOST is present" do
    it "does not change HTTP_HOST" do
      env = {
        "HTTP_HOST" => "practicaldev.herokuapp.com"
      }
      _status, result_env, _body = middleware.call(env)

      expect(result_env["HTTP_HOST"]).to eq("practicaldev.herokuapp.com")
    end
  end

  describe "host validation" do
    it "allows valid hostnames and localhost" do
      %w[mlh.forem.wtf sub-domain.example.com localhost localhost:3000].each do |valid_host|
        env = {
          "HTTP_HOST" => "practicaldev.herokuapp.com",
          "HTTP_FASTLY_ORIG_HOST" => valid_host
        }
        _status, result_env, _body = middleware.call(env)
        expect(result_env["HTTP_HOST"]).to eq(valid_host)
      end
    end

    it "rejects invalid hostnames (containing spaces, control characters, or invalid syntax)" do
      ["invalid host", "host\nname", "host;name", "http://host.com"].each do |invalid_host|
        env = {
          "HTTP_HOST" => "practicaldev.herokuapp.com",
          "HTTP_FASTLY_ORIG_HOST" => invalid_host
        }
        _status, result_env, _body = middleware.call(env)
        expect(result_env["HTTP_HOST"]).to eq("practicaldev.herokuapp.com")
      end
    end
  end
end
