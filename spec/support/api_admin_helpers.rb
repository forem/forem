module ApiAdminHelpers
  def admin_api_headers(user: nil)
    user ||= create(:user, :super_admin)
    secret = create(:api_secret, user: user).secret
    { "api-key" => secret, "Accept" => "application/vnd.forem.api-v1+json" }
  end

  def non_admin_api_headers
    user = create(:user)
    secret = create(:api_secret, user: user).secret
    { "api-key" => secret, "Accept" => "application/vnd.forem.api-v1+json" }
  end
end

RSpec.configure do |config|
  config.include ApiAdminHelpers, type: :request
end
