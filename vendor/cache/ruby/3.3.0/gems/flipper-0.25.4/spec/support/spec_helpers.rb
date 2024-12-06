require 'ice_age'
require 'json'
require 'rack/test'

module SpecHelpers
  def self.included(base)
    base.let(:flipper) { build_flipper }
    base.let(:app) { build_app(flipper) }
  end

  def build_app(flipper, options = {})
    Flipper::UI.app(flipper, options) do |builder|
      builder.use Rack::Session::Cookie, secret: 'test'
    end
  end

  def build_api(flipper, options = {})
    Flipper::Api.app(flipper, options)
  end

  def build_flipper(adapter = build_memory_adapter)
    Flipper.new(adapter)
  end

  def build_memory_adapter
    Flipper::Adapters::Memory.new
  end

  def json_response
    JSON.parse(last_response.body)
  end

  def api_error_code_reference_url
    'https://flippercloud.io/docs/api#error-code-reference'
  end

  def api_not_found_response
    {
      'code' => 1,
      'message' => 'Feature not found.',
      'more_info' => api_error_code_reference_url,
    }
  end

  def api_flipper_id_is_missing_response
    {
      'code' => 4,
      'message' => 'Required parameter flipper_id is missing.',
      'more_info' => api_error_code_reference_url,
    }
  end

  def api_positive_percentage_error_response
    {
      'code' => 3,
      'message' => 'Percentage must be a positive number less than or equal to 100.',
      'more_info' => api_error_code_reference_url,
    }
  end

  def silence
    # Store the original stderr and stdout in order to restore them later
    original_stderr = $stderr
    original_stdout = $stdout

    # Redirect stderr and stdout
    output = $stderr = $stdout = StringIO.new

    yield

    $stderr = original_stderr
    $stdout = original_stdout

    # Return output
    output.string
  end
end

RSpec.configure do |config|
  config.order = :random
  Kernel.srand config.seed

  config.include Rack::Test::Methods
  config.include SpecHelpers
end
