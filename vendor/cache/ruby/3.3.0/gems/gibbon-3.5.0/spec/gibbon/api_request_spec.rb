require 'spec_helper'
require 'webmock/rspec'

describe Gibbon::APIRequest do
  let(:api_key) { "1234-us1" }

  before do
    @gibbon = Gibbon::Request.new(api_key: api_key)
    @api_root = "https://us1.api.mailchimp.com/3.0"
    @basic_auth_credentials = ['apikey', api_key]
  end

  shared_examples_for 'client error handling' do
    it "surfaces client request exceptions as a Gibbon::MailChimpError" do
      exception = error_class.new("the server responded with status 503")
      stub_request(:get, "#{@api_root}/lists").with(basic_auth: @basic_auth_credentials).to_raise(exception)
      expect { @gibbon.lists.retrieve }.to raise_error(Gibbon::MailChimpError)
    end

    it "surfaces an unparseable client request exception as a Gibbon::MailChimpError" do
      exception = error_class.new(
        "the server responded with status 503")
      stub_request(:get, "#{@api_root}/lists").with(basic_auth: @basic_auth_credentials).to_raise(exception)
      expect { @gibbon.lists.retrieve }.to raise_error(Gibbon::MailChimpError)
    end

    it "surfaces an unparseable response body as a Gibbon::MailChimpError" do
      response_values = {:status => 503, :headers => {}, :body => '[foo]'}
      exception = error_class.new("the server responded with status 503", response_values)

      stub_request(:get, "#{@api_root}/lists").with(basic_auth: @basic_auth_credentials).to_raise(exception)
      expect { @gibbon.lists.retrieve }.to raise_error(Gibbon::MailChimpError)
    end

    context "handle_error" do
      it "includes status and raw body even when json can't be parsed" do
        response_values = {:status => 503, :headers => {}, :body => 'A non JSON response'}
        exception = error_class.new("the server responded with status 503", response_values)
        api_request = Gibbon::APIRequest.new(builder: Gibbon::Request)
        begin
          api_request.send :handle_error, exception
        rescue => boom
          expect(boom.status_code).to eq 503
          expect(boom.raw_body).to eq "A non JSON response"
        end
      end

      context "when symbolize_keys is true" do
        it "sets title and detail on the error params" do
          response_values = {:status => 422, :headers => {}, :body => '{"title": "foo", "detail": "bar"}'}
          exception = error_class.new("the server responded with status 422", response_values)
          api_request = Gibbon::APIRequest.new(builder: Gibbon::Request.new(symbolize_keys: true))
          begin
            api_request.send :handle_error, exception
          rescue => boom
            expect(boom.title).to eq "foo"
            expect(boom.detail).to eq "bar"
          end
        end
      end
    end
  end

  context 'Faraday::ClientError' do
    let(:error_class) { Faraday::ClientError }

    include_examples 'client error handling'
  end
end
