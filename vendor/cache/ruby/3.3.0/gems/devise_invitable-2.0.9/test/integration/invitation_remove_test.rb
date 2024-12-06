require 'test_helper'
require 'integration_tests_helper'

class InvitationRemoveTest < ActionDispatch::IntegrationTest

  test 'invited user can choose to remove his account/invite' do
    User.invite!(email: 'valid@email.com')

    # remove!
    visit remove_user_invitation_path(invitation_token: Thread.current[:token])
    assert_equal root_path, current_path
    assert page.has_css?('p#notice', text: 'Your invitation was removed.')
    
    # try to remove again!
    visit remove_user_invitation_path(invitation_token: Thread.current[:token])
    assert_equal root_path, current_path
    assert page.has_css?('p#alert', text: 'The invitation token provided is not valid!')
  end

  test 'accepted user cannot remove his account (by using the original invitation token)' do
    user = User.invite!(email: 'valid@email.com')
    saved_token = Thread.current[:token]
    user.accept_invitation!
    
    visit remove_user_invitation_path(invitation_token: saved_token)
    assert_equal root_path, current_path
    assert page.has_css?('p#alert', text: 'The invitation token provided is not valid!')
  end
end
