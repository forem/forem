require 'test_helper'

class RoutesTest < ActionController::TestCase

  test 'map new user invitation' do
    assert_recognizes({ controller: 'devise/invitations', action: 'new' }, { path: 'users/invitation/new', method: :get })
  end

  test 'map create user invitation' do
    assert_recognizes({ controller: 'devise/invitations', action: 'create' }, { path: 'users/invitation', method: :post })
  end

  test 'map accept user invitation' do
    assert_recognizes({ controller: 'devise/invitations', action: 'edit' }, 'users/invitation/accept')
  end

  test 'map update user invitation' do
    assert_recognizes({ controller: 'devise/invitations', action: 'update' }, { path: 'users/invitation', method: :put })
  end
end
