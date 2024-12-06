require 'test_helper'

class ControllerHelpersTest < ActionController::TestCase
  tests ApplicationController

  test "after invite path defaults to after sign in path" do
    assert_equal @controller.send(:after_sign_in_path_for, :user), @controller.after_invite_path_for(:user)
  end

  test "after accept path defaults to after sign in path" do
    assert_equal @controller.send(:after_sign_in_path_for, :user), @controller.after_accept_path_for(:user)
  end

  test 'after invite path is customizable from application controller' do
    custom_path = 'customized/after/invite/path'
    @controller.instance_eval "def after_invite_path_for(resource) '#{custom_path}' end"
    assert_equal @controller.after_invite_path_for(:user), custom_path
  end

  test 'after invite path is customizable from application controller with invited' do
    custom_path = 'customized/after/invite/path'
    @controller.instance_eval "def after_invite_path_for(resource, invited) '#{custom_path}' end"
    assert_equal @controller.after_invite_path_for(:user, :invited), custom_path
  end
  test 'after accept path is customizable from application controller' do
    custom_path = 'customized/after/accept/path'
    @controller.instance_eval "def after_accept_path_for(resource) '#{custom_path}' end"
    assert_equal @controller.after_accept_path_for(:user), custom_path
  end

  test 'is not a devise controller' do
    assert !@controller.devise_controller?
  end

  test 'invitations controller respects definition for after invite path in application controller' do
    assert Devise::InvitationsController.method_defined? :after_invite_path_for
    assert !Devise::InvitationsController.instance_methods(false).include?(:after_invite_path_for)
  end

  test 'invitations controller respects definition for after accept path in application controller' do
    assert Devise::InvitationsController.method_defined? :after_accept_path_for
    assert !Devise::InvitationsController.instance_methods(false).include?(:after_accept_path_for)
  end

  test 'invalid token path defaults to after sign out path' do
    assert_equal @controller.send(:after_sign_out_path_for, :user), @controller.invalid_token_path_for(:user)
  end

  test 'invalid token path is customizable from application controller' do
    custom_path = 'customized/invalid/token/path'
    @controller.instance_eval "def invalid_token_path_for(resource_name) '#{custom_path}' end"
    assert_equal @controller.invalid_token_path_for(:user), custom_path
  end
end
