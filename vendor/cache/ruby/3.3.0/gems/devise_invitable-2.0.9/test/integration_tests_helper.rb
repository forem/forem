class ActionDispatch::IntegrationTest

  def warden
    request.env['warden']
  end

  def create_full_user
    @user ||= begin
      user = User.create!(
        username: 'usertest',
        email: 'fulluser@test.com',
        password: '123456',
        password_confirmation: '123456',
        created_at: Time.now.utc,
      )
      user.confirm
      user
    end
  end

  def sign_in_as_user(user = nil)
    user ||= create_full_user
    resource_name = user.class.name.underscore
    visit send("new_#{resource_name}_session_path")
    fill_in "#{resource_name}_email", with: user.email
    fill_in "#{resource_name}_password", with: user.password
    click_button 'Log in'
  end

  # Fix assert_redirect_to in integration sessions because they don't take into
  # account Middleware redirects.
  def assert_redirected_to(url)
    assert [301, 302].include?(@integration_session.status),
           "Expected status to be 301 or 302, got #{@integration_session.status}"

    url = prepend_host(url)
    location = prepend_host(@integration_session.headers['Location'])
    assert_equal url, location
  end

  protected

    def prepend_host(url)
      url = "http://#{request.host}#{url}" if url[0] == ?/
      url
    end
end
