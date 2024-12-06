require 'test_helper'
require 'model_tests_helper'

class DeviseInvitable::RegistrationsControllerTest < ActionController::TestCase
  def setup
    @issuer = new_user#users(:issuer)
    @issuer.valid?
    assert @issuer.valid?, 'starting with a valid user record'

    # josevalim: you are required to do that because the routes sets this kind
    # of stuff automatically. But functional tests are not using the routes.
    # see https://github.com/plataformatec/devise/issues/1196
    @request.env['devise.mapping'] = Devise.mappings[:user]
  end

  test "invited users may still sign up directly by themselves" do
    # invite the invitee
    sign_in @issuer
    invitee_email = 'invitee@example.org'

    User.invite!(email: invitee_email) do |u|
      u.skip_invitation = true
      u.invited_by = @issuer
    end
    sign_out @issuer

    @invitee = User.where(email: invitee_email).first
    assert_nil @invitee.invitation_accepted_at
    assert_not_nil @invitee.invitation_token
    assert !@invitee.confirmed?

    # sign_up the invitee
    assert_difference('ActionMailer::Base.deliveries.size') do
      post :create, params: { user: { email: invitee_email, password: '1password', bio: '.' } }
    end

    @invitee = User.where(email: invitee_email).first

    # do not send emails on model changes
    assert_difference('ActionMailer::Base.deliveries.size', 0) do
      @invitee.bio = 'I am a robot'
      @invitee.save!
      @invitee.bio = 'I am a human'
      @invitee.save!
    end

    assert @invitee.encrypted_password.present?
    assert_not_nil @invitee.invitation_accepted_at
    assert_nil @invitee.invitation_token
    assert @invitee.invited_by_id.present?
    assert @invitee.invited_by_type.present?
    assert @invitee.confirmation_token.present?
    assert !@invitee.confirmed?
  end

  test "non-invited users may still sign up directly by themselves" do
    register_email = 'invitee@example.org'
    # sign_up the invitee
    assert_difference('ActionMailer::Base.deliveries.size') do
      post :create, params: { user: { email: register_email, password: '1password', bio: '.' } }
    end
    assert_nil @controller.current_user

    @user = User.where(email: register_email).first

    # do not send emails on model changes
    assert_no_difference('ActionMailer::Base.deliveries.size') do
      @user.bio = 'I am a robot'
      @user.save!
      @user.bio = 'I am a human'
      @user.save!
    end

    assert @user.encrypted_password.present?
    assert_nil @user.invitation_accepted_at
    assert_nil @user.invitation_token
    assert_nil @user.invited_by
    assert @user.confirmation_token.present?
    assert !@user.confirmed?
  end

  test "not invitable resources can register" do
    @request.env['devise.mapping'] = Devise.mappings[:admin]
    invitee_email = 'invitee@example.org'

    assert_nil Admin.where(email: invitee_email).first

    post :create, params: { admin: { email: invitee_email, password: '1password' } }

    @invitee = Admin.where(email: invitee_email).first
    assert @invitee.encrypted_password.present?
  end

  test "not invitable resources are not logged in after sign up again" do
    @request.env['devise.mapping'] = Devise.mappings[:admin]
    invitee_email = 'invitee@example.org'

    post :create, params: { admin: { email: invitee_email, password: '1password' } }
    assert_response 302

    @invitee = Admin.where(email: invitee_email).first
    assert @invitee.encrypted_password.present?

    sign_out @invitee
    post :create, params: { admin: { email: invitee_email, password: "2password" } }
    assert_response 200
    assert_equal @invitee.encrypted_password, Admin.where(email: invitee_email).first.encrypted_password
    assert @controller.send(:resource).errors.present?
  end

  test "missing params on a create should not cause an error" do
    assert_nothing_raised { post :create }
  end
end
