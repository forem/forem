RSpec.configure do |config|
  include Warden::Test::Helpers
  Warden.test_mode!

  config.after(:each) do
    Warden.test_reset!
  end

  # def sign_in(user, opts = {})
  #   login_as(user, opts)
  # end
  #
  # def sign_out(*scopes)
  #   logout(*scopes)
  # end
end
