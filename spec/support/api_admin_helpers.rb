module ApiAdminHelpers
  # Builds v1 API request headers authenticated with an ApiSecret for a super-admin user.
  #
  # @param user [User, nil] optional user to attach the API secret to; creates a lightweight super_admin when nil
  # @return [Hash{String => String}] request headers containing "api-key" and v1 "Accept"
  def admin_api_headers(user: nil)
    user ||= create(:user, :super_admin, :without_profile, profile_image: nil)
    secret = create(:api_secret, user: user).secret
    { "api-key" => secret, "Accept" => "application/vnd.forem.api-v1+json" }
  end

  # Builds v1 API request headers authenticated with an ApiSecret for a non-admin user.
  #
  # @return [Hash{String => String}] request headers containing "api-key" and v1 "Accept"
  def non_admin_api_headers
    user = create(:user, :without_profile, profile_image: nil)
    secret = create(:api_secret, user: user).secret
    { "api-key" => secret, "Accept" => "application/vnd.forem.api-v1+json" }
  end
end

RSpec.configure do |config|
  config.include ApiAdminHelpers, type: :request
end
