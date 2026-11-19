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

  context "when HTTP_X_FOREM_ORIGINAL_HOST is present" do
    it "overrides HTTP_HOST with the value of HTTP_X_FOREM_ORIGINAL_HOST" do
      env = {
        "HTTP_HOST" => "practicaldev.herokuapp.com",
        "HTTP_X_FOREM_ORIGINAL_HOST" => "mlh.forem.wtf"
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

    it "takes the first host when HTTP_X_FORWARDED_HOST has comma-separated values", :aggregate_failures do
      env = {
        "HTTP_HOST" => "practicaldev.herokuapp.com",
        "HTTP_X_FORWARDED_HOST" => "mlh.forem.wtf, practicaldev.herokuapp.com"
      }
      _status, result_env, _body = middleware.call(env)

      expect(result_env["HTTP_HOST"]).to eq("mlh.forem.wtf")
      expect(result_env["HTTP_X_FORWARDED_HOST"]).to be_nil
      expect(ActionDispatch::Request.new(result_env).host).to eq("mlh.forem.wtf")
    end
  end

  context "when HTTP_X_FORWARDED_HOST is present and environment is production" do
    before do
      allow(Rails.env).to receive(:production?).and_return(true)
    end

    context "when TRUST_X_FORWARDED_HOST is enabled" do
      before do
        stub_const("ENV", ENV.to_h.merge("TRUST_X_FORWARDED_HOST" => "true"))
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

    context "when TRUST_X_FORWARDED_HOST is not enabled" do
      before do
        stub_const("ENV", ENV.to_h.merge("TRUST_X_FORWARDED_HOST" => nil))
      end

      it "does not override HTTP_HOST to prevent host spoofing", :aggregate_failures do
        env = {
          "HTTP_HOST" => "practicaldev.herokuapp.com",
          "HTTP_X_FORWARDED_HOST" => "mlh.forem.wtf"
        }
        _status, result_env, _body = middleware.call(env)

        expect(result_env["HTTP_HOST"]).to eq("practicaldev.herokuapp.com")
        expect(result_env["HTTP_X_FORWARDED_HOST"]).to be_nil
        expect(ActionDispatch::Request.new(result_env).host).to eq("practicaldev.herokuapp.com")
        expect(Rack::Request.new(result_env).host).to eq("practicaldev.herokuapp.com")
      end

      it "clears malformed HTTP_X_FORWARDED_HOST values", :aggregate_failures do
        ["'\"efx", "/efx"].each do |malformed_host|
          env = {
            "HTTP_HOST" => "practicaldev.herokuapp.com",
            "HTTP_X_FORWARDED_HOST" => malformed_host
          }
          _status, result_env, _body = middleware.call(env)

          expect(result_env["HTTP_HOST"]).to eq("practicaldev.herokuapp.com")
          expect(result_env["HTTP_X_FORWARDED_HOST"]).to be_nil
          expect(ActionDispatch::Request.new(result_env).host).to eq("practicaldev.herokuapp.com")
        end
      end
    end
  end

  context "when both HTTP_X_FOREM_ORIGINAL_HOST, HTTP_FASTLY_ORIG_HOST and HTTP_X_FORWARDED_HOST are present" do
    it "prioritizes HTTP_X_FOREM_ORIGINAL_HOST", :aggregate_failures do
      env = {
        "HTTP_HOST" => "practicaldev.herokuapp.com",
        "HTTP_X_FOREM_ORIGINAL_HOST" => "forem-original.com",
        "HTTP_FASTLY_ORIG_HOST" => "fastly-orig.com",
        "HTTP_X_FORWARDED_HOST" => "forwarded.com"
      }
      _status, result_env, _body = middleware.call(env)

      expect(result_env["HTTP_HOST"]).to eq("forem-original.com")
      expect(result_env["HTTP_X_FORWARDED_HOST"]).to be_nil
      expect(ActionDispatch::Request.new(result_env).host).to eq("forem-original.com")
    end
  end

  context "when none of HTTP_X_FOREM_ORIGINAL_HOST, HTTP_FASTLY_ORIG_HOST, or HTTP_X_FORWARDED_HOST is present" do
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

    it "rejects invalid hostnames (containing spaces, control characters, or invalid syntax)", :aggregate_failures do
      ["invalid host", "host\nname", "host;name", "http://host.com", "'\"efx", "/efx"].each do |invalid_host|
        env = {
          "HTTP_HOST" => "practicaldev.herokuapp.com",
          "HTTP_FASTLY_ORIG_HOST" => invalid_host
        }
        _status, result_env, _body = middleware.call(env)
        expect(result_env["HTTP_HOST"]).to eq("practicaldev.herokuapp.com")
      end
    end

    it "clears invalid HTTP_X_FORWARDED_HOST values even when trusted", :aggregate_failures do
      allow(Rails.env).to receive(:production?).and_return(false)

      ["'\"efx", "/efx", "invalid host"].each do |invalid_host|
        env = {
          "HTTP_HOST" => "practicaldev.herokuapp.com",
          "HTTP_X_FORWARDED_HOST" => invalid_host
        }
        _status, result_env, _body = middleware.call(env)
        expect(result_env["HTTP_HOST"]).to eq("practicaldev.herokuapp.com")
        expect(result_env["HTTP_X_FORWARDED_HOST"]).to be_nil
        expect(ActionDispatch::Request.new(result_env).host).to eq("practicaldev.herokuapp.com")
      end
    end
  end
end
