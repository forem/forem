module FeatureHelpers
  def login_via_session_as(user)
    page.set_rack_session('warden.user.user.key' => User.serialize_into_session(user))
  end
end
