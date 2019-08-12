module RequestHelper
  # Add support for testing `options` requests in RSpec.
  # See: https://github.com/rspec/rspec-rails/issues/925
  def options(*args)
    reset! unless integration_session
    integration_session.__send__(:process, :options, *args).tap do
      copy_session_variables!
    end
  end
end

RSpec.configure do |config|
  config.include RequestHelper, type: :request
end
