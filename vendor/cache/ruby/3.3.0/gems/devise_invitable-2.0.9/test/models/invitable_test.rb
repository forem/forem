require 'test_helper'
require 'model_tests_helper'

class Validatable < User
  devise :validatable, password_length: 10..20
end

class InvitableTest < ActiveSupport::TestCase

  def setup
    setup_mailer
  end

  test 'should not generate invitation token after creating a record' do
    assert_nil new_user.invitation_token
  end

  test 'should update the invitations count counter cache' do
    if defined?(ActiveRecord)
      current_user = new_user
      2.times do |index|
        User.invite!({ email: "valid#{index}@email.com" }, current_user)
      end
      assert_equal current_user.reload.invitations_count, 2
    end
  end

  test 'should not generate the raw invitation token after creating a record' do
    assert_nil new_user.raw_invitation_token
  end

  test 'should regenerate invitation token each time' do
    user = new_user
    user.invite!

    refute_nil user.invitation_token
    refute_nil user.raw_invitation_token
    refute_nil user.invitation_created_at

    3.times do
      user = User.find(user.id)

      assert_not_same user.invitation_token, lambda {
        user.invite!
        user.invitation_token
      }.call
      refute_nil user.raw_invitation_token
    end
  end

  test 'should regenerate invitation token each time even if "skip_invitation" was true' do
    user = new_user
    user.skip_invitation = true
    user.invite!

    refute_nil user.invitation_token
    refute_nil user.invitation_created_at

    3.times do
      user = User.find(user.id)
      user.skip_invitation = true

      assert_not_same user.invitation_token, lambda {
        user.invite!
        user.invitation_token
      }.call
      refute_nil user.invitation_token
      refute_nil user.raw_invitation_token
    end
  end

  test 'should alias the invitation_token method with encrypted_invitation_token' do
    user = new_user
    user.invite!
    assert_equal user.invitation_token, user.encrypted_invitation_token
  end

  test 'should return the correct raw_invitation_token ' do
    user = new_user
    raw, enc = Devise.token_generator.generate(user.class, :invitation_token)
    # stub the generator so the tokens are the same
    Devise.token_generator.stubs(:generate).returns([raw, enc])
    user.invite!
    assert_equal user.raw_invitation_token, raw
  end

  test 'should set invitation created and sent at each time' do
    user = new_user
    user.invite!
    old_invitation_created_at = 3.days.ago
    old_invitation_sent_at = 3.days.ago
    user.update(invitation_sent_at: old_invitation_sent_at, invitation_created_at: old_invitation_created_at)
    3.times do
      user.invite!
      refute_equal old_invitation_sent_at, user.invitation_sent_at
      refute_equal old_invitation_created_at, user.invitation_created_at
      user.update(invitation_sent_at: old_invitation_sent_at, invitation_created_at: old_invitation_created_at)
    end
  end

  test 'should test invitation sent at with invite_for configuration value' do
    user = User.invite!(email: 'valid@email.com')

    User.stubs(:invite_for).returns(nil)
    user.invitation_created_at = Time.now.utc
    assert_predicate user, :valid_invitation?

    User.stubs(:invite_for).returns(nil)
    user.invitation_created_at = 1.year.ago
    assert_predicate user, :valid_invitation?

    User.stubs(:invite_for).returns(0)
    user.invitation_created_at = Time.now.utc
    assert_predicate user, :valid_invitation?

    User.stubs(:invite_for).returns(0)
    user.invitation_created_at = 1.day.ago
    assert_predicate user, :valid_invitation?

    User.stubs(:invite_for).returns(1.day)
    user.invitation_created_at = Time.now.utc
    assert_predicate user, :valid_invitation?

    User.stubs(:invite_for).returns(1.day)
    user.invitation_created_at = 2.days.ago
    refute_predicate user, :valid_invitation?
  end

  test 'should return token validity when there is invite_for' do
    User.stubs(:invite_for).returns(1.day)

    user = User.invite!(email: 'valid@email.com')
    sent_at = user.invitation_created_at || user.invitation_sent_at
    valid_until = sent_at + User.invite_for

    assert_equal user.invitation_due_at, valid_until
  end

  test 'should return nil for invitation due date when invite_for is nil' do
    User.stubs(:invite_for).returns(nil)
    user = User.invite!(email: 'valid@email.com')

    assert_nil user.invitation_due_at
  end

  test 'should return nil for invitation due date when invite_for is 0' do
    User.stubs(:invite_for).returns(0)
    user = User.invite!(email: 'valid@email.com')

    assert_nil user.invitation_due_at
  end

  test 'should never generate the same invitation token for different users' do
    invitation_tokens = []
    3.times do
      user = new_user
      user.invite!
      token = user.invitation_token
      refute_includes invitation_tokens, token
      invitation_tokens << token
    end
  end

  test 'should invite with multiple columns for invite key' do
    User.stubs(:invite_key).returns(email: Devise.email_regexp, username: /\A.+\z/)
    user = User.invite!(email: 'valid@email.com', username: "name")
    assert_predicate user, :persisted?
    assert_empty user.errors
  end

  test 'should allow non-string columns for invite key' do
    User.stubs(:invite_key).returns(email: Devise.email_regexp, profile_id: :present?.to_proc)
    user = User.invite!(email: 'valid@email.com', profile_id: 1)
    assert_predicate user, :persisted?
    assert_empty user.errors
  end

  test 'should not invite with some missing columns when invite key is an array' do
    User.stubs(:invite_key).returns(email: Devise.email_regexp, username: /\A.+\z/, profile_id: :present?.to_proc, active: true)
    user = User.invite!(email: 'valid@email.com')
    assert_predicate user, :new_record?
    refute_empty user.errors
    assert user.errors[:username]
    assert user.errors[:profile_id]
    assert user.errors[:active]
    assert_empty user.errors[:email]
  end

  test 'should return mail object' do
    mail = User.invite_mail!(email: 'valid@email.com')
    assert_instance_of Mail::Message, mail
  end

  test 'should disallow login when invited' do
    invited_user = User.invite!(email: 'valid@email.com')
    refute invited_user.valid_password?('1234')
  end

  test 'should not accept invite without password' do
    User.invite!(email: 'valid@email.com')
    User.accept_invitation!(invitation_token: Thread.current[:token])
    refute_predicate User.where(email: 'valid@email.com').first, :invitation_accepted?
  end

  test 'should accept invite without password if enforce is disabled' do
    Devise.stubs(require_password_on_accepting: false)
    User.invite!(email: 'valid@email.com')
    User.accept_invitation!(invitation_token: Thread.current[:token])
    assert_predicate User.where(email: 'valid@email.com').first, :invitation_accepted?
  end

  test 'should set password and password confirmation from params' do
    User.invite!(email: 'valid@email.com')
    user = User.accept_invitation!(invitation_token: Thread.current[:token], password: '123456789', password_confirmation: '123456789')
    assert user.valid_password?('123456789')
  end

  test 'should set password and save the record' do
    user = User.invite!(email: 'valid@email.com')
    old_encrypted_password = user.encrypted_password
    user = User.accept_invitation!(invitation_token: Thread.current[:token], password: '123456789', password_confirmation: '123456789')
    refute_equal old_encrypted_password, user.encrypted_password
  end

  test 'should not override password on invite!' do
    user = User.invite!(email: 'valid@email.com', password: 'password', password_confirmation: 'password', skip_invitation: true)
    assert user.valid?
  end

  test 'should clear invitation token and set invitation_accepted_at while accepting the password' do
    user = User.invite!(email: 'valid@email.com')
    assert user.invitation_token.present?
    assert_nil user.invitation_accepted_at
    user.accept_invitation!
    assert_nil user.invitation_token
    assert user.invitation_accepted_at.present?
    assert user.invitation_accepted?
    user.reload
    assert_nil user.invitation_token
    assert user.invitation_accepted_at.present?
    assert user.invitation_accepted?
  end

  test 'should not clear invitation token or set accepted_at if record is invalid' do
    user = User.invite!(email: 'valid@email.com')
    assert user.invitation_token.present?
    assert_nil user.invitation_accepted_at
    old_encrypted_password = user.encrypted_password
    User.accept_invitation!(invitation_token: user.invitation_token, password: '123456789', password_confirmation: '987654321')
    user.reload
    assert_equal old_encrypted_password, user.encrypted_password
    assert user.invitation_token.present?
    assert_nil user.invitation_accepted_at
  end

  test 'should not require reloading if invalid' do
    user = User.invite!(email: 'valid@email.com')
    assert user.invitation_token.present?
    assert_nil user.invitation_accepted_at
    user.attributes = { password: '123456789', password_confirmation: '987654321' }
    user.accept_invitation!
    assert user.invitation_token.present?
    assert_nil user.invitation_accepted_at
    assert !user.invitation_accepted?
  end

  test 'should clear invitation token while resetting the password' do
    user = User.invite!(email: 'valid@email.com')
    assert user.invited_to_sign_up?
    token, user.reset_password_token = Devise.token_generator.generate(User, :reset_password_token)
    user.reset_password_sent_at = Time.now.utc
    user.save

    assert user.reset_password_token.present?
    assert user.invitation_token.present?
    User.reset_password_by_token(reset_password_token: token, password: '123456789', password_confirmation: '123456789')
    assert_nil user.reload.reset_password_token
    assert_nil user.reload.invitation_token
    refute_predicate user, :invited_to_sign_up?
  end

  test 'should not accept expired invitation while resetting the password' do
    User.stubs(:invite_for).returns(1.day)
    user = User.invite!(email: 'valid@email.com')
    assert user.invited_to_sign_up?
    user.invitation_created_at = Time.now.utc - 2.days
    token, user.reset_password_token = Devise.token_generator.generate(User, :reset_password_token)
    user.reset_password_sent_at = Time.now.utc
    user.save

    assert user.reset_password_token.present?
    assert user.invitation_token.present?
    User.reset_password_by_token(reset_password_token: token, password: '123456789', password_confirmation: '123456789')
    assert_nil user.reload.reset_password_token
    assert user.reload.invitation_token.present?
    assert user.reload.invited_to_sign_up?
  end

  test 'should not accept invitation on failing to reset the password' do
    user = User.invite!(email: 'valid@email.com')
    assert user.invited_to_sign_up?
    token, user.reset_password_token = Devise.token_generator.generate(User, :reset_password_token)
    user.reset_password_sent_at = Time.now.utc
    user.save

    assert user.reset_password_token.present?
    assert user.invitation_token.present?
    User.reset_password_by_token(reset_password_token: token, password: '123456789', password_confirmation: '12345678')
    assert user.reload.reset_password_token.present?
    assert user.reload.invitation_token.present?
    assert user.invited_to_sign_up?
  end

  test 'should not set invitation_accepted_at if just resetting password' do
    user = User.create!(email: 'valid@email.com', password: '123456780')
    refute_predicate user, :invited_to_sign_up?
    token, user.reset_password_token = Devise.token_generator.generate(User, :reset_password_token)
    user.reset_password_sent_at = Time.now.utc
    user.save

    assert user.reset_password_token.present?
    assert_nil user.invitation_token
    User.reset_password_by_token(reset_password_token: token, password: '123456789', password_confirmation: '123456789')
    assert_nil user.reload.invitation_token
    assert_nil user.reload.invitation_accepted_at
  end

  test 'should reset invitation token and send invitation by email' do
    user = new_user
    assert_difference('ActionMailer::Base.deliveries.size') do
      token = user.invitation_token
      user.invite!
      refute_equal token, user.invitation_token
    end
  end

  test 'should return a record with invitation token and no errors to send invitation by email' do
    invited_user = User.invite!(email: 'valid@email.com')
    assert_empty invited_user.errors
    assert_predicate invited_user.invitation_token, :present?
    assert_equal 'valid@email.com', invited_user.email
    assert_predicate invited_user, :persisted?
  end

  test 'should set all attributes with no errors' do
    invited_user = User.invite!(email: 'valid@email.com', username: 'first name')
    assert_empty invited_user.errors
    assert_equal 'first name', invited_user.username
    assert_predicate invited_user, :persisted?
  end

  test 'should not validate other attributes when validate_on_invite is disabled' do
    validate_on_invite = User.validate_on_invite
    User.validate_on_invite = false
    invited_user = User.invite!(email: 'valid@email.com', username: 'a' * 50)
    assert_empty invited_user.errors
    User.validate_on_invite = validate_on_invite
  end

  test 'should validate other attributes when validate_on_invite is enabled' do
    validate_on_invite = User.validate_on_invite
    User.validate_on_invite = true
    invited_user = User.invite!(email: 'valid@email.com', username: 'a' * 50)
    refute_empty invited_user.errors[:username]
    User.validate_on_invite = validate_on_invite
  end

  test 'should not validate password when validate_on_invite is enabled' do
    validate_on_invite = User.validate_on_invite
    User.validate_on_invite = true
    invited_user = User.invite!(email: 'valid@email.com', username: 'a' * 50)
    refute_empty invited_user.errors
    assert_empty invited_user.errors[:password]
    User.validate_on_invite = validate_on_invite
  end

  test 'should validate other attributes when validate_on_invite is enabled and email is not present' do
    validate_on_invite = User.validate_on_invite
    User.validate_on_invite = true
    invited_user = User.invite!(email: '', username: 'a' * 50)
    refute_empty invited_user.errors[:email]
    refute_empty invited_user.errors[:username]
    User.validate_on_invite = validate_on_invite
  end

  test 'should not validate other attributes when validate_on_invite is disabled (for instance method)' do
    validate_on_invite = User.validate_on_invite
    User.validate_on_invite = false
    user = new_user(email: 'valid@email.com', username: 'a' * 50)
    user.invite!(nil, validate: false)
    assert_empty user.errors
    User.validate_on_invite = validate_on_invite
  end

  test 'should validate other attributes when validate_on_invite is disabled and validate option is enabled (for instance method)' do
    validate_on_invite = User.validate_on_invite
    User.validate_on_invite = false
    user = new_user(email: 'valid@email.com', username: 'a' * 50)
    user.invite!(nil, validate: true)
    refute_empty user.errors[:username]
    User.validate_on_invite = validate_on_invite
  end

  test 'should validate other attributes when validate_on_invite is enabled and validate option is disabled (for instance method)' do
    validate_on_invite = User.validate_on_invite
    User.validate_on_invite = true
    user = new_user(email: 'valid@email.com', username: 'a' * 50)
    user.invite!
    refute_empty user.errors[:username]
    User.validate_on_invite = validate_on_invite
  end

  test 'should validate other attributes when validate_on_invite is enabled and validate option is disabled explicitly (for instance method)' do
    validate_on_invite = User.validate_on_invite
    User.validate_on_invite = true
    user = new_user(email: 'valid@email.com', username: 'a' * 50)
    user.invite!(nil, validate: false)
    assert_empty user.errors
    User.validate_on_invite = validate_on_invite
  end

  test 'should return a record with errors if user was found by e-mail' do
    existing_user = User.new(email: 'valid@email.com')
    existing_user.save(validate: false)
    user = User.invite!(email: 'valid@email.com')
    assert_equal user, existing_user
    assert_equal [{error: :taken}], user.errors.details[:email]
    same_user = User.invite!(email: 'valid@email.com')
    assert_equal same_user, existing_user
    assert_equal [{error: :taken}], same_user.errors.details[:email]
  end

  test 'should return a record with errors if user with pending invitation was found by e-mail' do
    existing_user = User.invite!(email: 'valid@email.com')
    user = User.invite!(email: 'valid@email.com')
    assert_equal user, existing_user
    assert_equal [], user.errors[:email]
    resend_invitation = User.resend_invitation
    begin
      User.resend_invitation = false

      user = User.invite!(email: 'valid@email.com')
      assert_equal user, existing_user
      assert_equal [{error: :taken}], user.errors.details[:email]
    ensure
      User.resend_invitation = resend_invitation
    end
  end

  test 'should return a record with errors if user was found by e-mail with validate_on_invite' do
    begin
      validate_on_invite = User.validate_on_invite
      User.validate_on_invite = true
      existing_user = User.new(email: 'valid@email.com')
      existing_user.save(validate: false)
      user = User.invite!(email: 'valid@email.com', username: 'a' * 50)
      assert_equal user, existing_user
      assert_equal [{error: :taken}], user.errors.details[:email]
      refute_empty user.errors[:username]
    ensure
      User.validate_on_invite = validate_on_invite
    end
  end

  test 'should return a new record with errors if e-mail is blank' do
    invited_user = User.invite!(email: '')
    assert invited_user.new_record?
    assert_equal [{error: :blank}], invited_user.errors.details[:email]
  end

  test 'should return a new record with errors if e-mail is invalid' do
    invited_user = User.invite!(email: 'invalid_email')
    assert invited_user.new_record?
    assert_equal [{error: :invalid}], invited_user.errors.details[:email]
  end

  test 'should set all attributes with errors if e-mail is invalid' do
    invited_user = User.invite!(email: 'invalid_email.com', username: 'first name')
    assert invited_user.new_record?
    assert_equal 'first name', invited_user.username
    refute_empty invited_user.errors
  end

  test 'should find a user to set his password based on invitation_token' do
    user = new_user
    user.invite!
    invited_user = User.accept_invitation!(invitation_token: Thread.current[:token])
    assert_equal invited_user, user
  end

  test 'should return a new record with errors if no invitation_token is found' do
    invited_user = User.accept_invitation!(invitation_token: 'invalid_token')
    assert invited_user.new_record?
    assert_equal [{error: :invalid}], invited_user.errors.details[:invitation_token]
  end

  test 'should return a new record with errors if invitation_token is blank' do
    invited_user = User.accept_invitation!(invitation_token: '')
    assert invited_user.new_record?
    assert_equal [{error: :blank}], invited_user.errors.details[:invitation_token]
  end

  test 'should return record with errors if invitation_token has expired' do
    User.stubs(:invite_for).returns(10.hours)
    invited_user = User.invite!(email: 'valid@email.com')
    invited_user.invitation_created_at = 2.days.ago
    invited_user.save(validate: false)
    user = User.accept_invitation!(invitation_token: Thread.current[:token])
    assert_equal user, invited_user
    assert_equal [{error: :invalid}], user.errors.details[:invitation_token]
  end

  test 'should allow record modification using block' do
    invited_user = User.invite!(email: 'valid@email.com', username: 'a' * 50) do |u|
      u.password = '123123'
      u.password_confirmation = '123123'
    end
    assert_equal '123123', invited_user.reload.password
  end

  test 'should set successfully user password given the new password and confirmation' do
    user = new_user(password: nil, password_confirmation: nil)
    user.invite!

    User.accept_invitation!(
      invitation_token: Thread.current[:token],
      password: 'new_password',
      password_confirmation: 'new_password',
    )
    user.reload

    assert user.valid_password?('new_password')
  end

  test 'should return errors on other attributes even when password is valid' do
    user = new_user(password: nil, password_confirmation: nil)
    user.invite!

    invited_user = User.accept_invitation!(
      invitation_token: Thread.current[:token],
      password: 'new_password',
      password_confirmation: 'new_password',
      username: 'a' * 50,
    )
    refute_empty invited_user.errors[:username]

    user.reload
    refute user.valid_password?('new_password')
  end

  test 'should check if created by invitation' do
    user = User.invite!(email: 'valid@email.com')
    assert user.created_by_invite?

    invited_user = User.accept_invitation!(
      invitation_token: Thread.current[:token],
      password: 'new_password',
      password_confirmation: 'new_password',
      username: 'a',
    )
    user.reload
    assert user.created_by_invite?
  end


  test 'should set other attributes on accepting invitation' do
    user = new_user(password: nil, password_confirmation: nil)
    user.invite!

    invited_user = User.accept_invitation!(
      invitation_token: Thread.current[:token],
      password: 'new_password',
      password_confirmation: 'new_password',
      username: 'a',
    )
    assert invited_user.errors[:username].blank?

    user.reload
    assert_equal 'a', user.username
    assert user.valid_password?('new_password')
  end

  test 'should not confirm user on invite' do
    user = new_user

    user.invite!

    refute_predicate user, :confirmed?
  end

  test 'user.has_invitations_left? test' do
    # By default with invitation_limit nil, users can send unlimited invitations
    user = new_user
    assert_nil user.invitation_limit
    assert user.has_invitations_left?

    # With invitation_limit set to a value, all users can send that many invitations
    User.stubs(:invitation_limit).returns(2)
    assert user.has_invitations_left?

    # With an individual invitation_limit of 0, a user shouldn't be able to send an invitation
    user.invitation_limit = 0
    assert user.save
    refute_predicate user, :has_invitations_left?

    # With in invitation_limit of 2, a user should be able to send two invitations
    user.invitation_limit = 2
    assert user.save
    assert user.has_invitations_left?
  end

  test 'should not send an invitation if we want to skip the invitation' do
    assert_no_difference('ActionMailer::Base.deliveries.size') do
      User.invite!(email: 'valid@email.com', username: 'a' * 50, skip_invitation: true)
    end
  end

  test 'should not send an invitation if we want to skip the invitation with block' do
    assert_no_difference('ActionMailer::Base.deliveries.size') do
      User.invite!(email: 'valid@email.com', username: 'a' * 50) do |u|
        u.skip_invitation = true
      end
    end
  end

  test 'user.invite! should not send an invitation if we want to skip the invitation' do
    user = new_user
    user.skip_invitation = true
    assert_no_difference('ActionMailer::Base.deliveries.size') do
      user.invite!
    end
    assert_predicate user, :invitation_created_at
    assert_nil user.invitation_sent_at
  end

  test 'user.invite! should not send an invitation if we want to skip the invitation with block' do
    user = new_user
    assert_no_difference('ActionMailer::Base.deliveries.size') do
      user.invite! do |u|
        u.skip_invitation = true
      end
    end
    assert_predicate user, :invitation_created_at
    assert_nil user.invitation_sent_at
  end

  test 'user.invite! should not set the invited_by attribute if not passed' do
    user = new_user
    user.invite!
    assert_nil user.invited_by
  end

  test 'user.invite! should set the invited_by attribute if passed' do
    user = new_user
    inviting_user = User.new(email: 'valid@email.com')
    inviting_user.save(validate: false)
    user.invite!(inviting_user)
    assert_equal inviting_user, user.invited_by
    assert_equal inviting_user.class.to_s, user.invited_by_type
  end

  test 'user.accept_invitation! should trigger callbacks' do
    user = User.invite!(email: 'valid@email.com')
    assert_callbacks_not_fired :after_invitation_accepted, user
    user.accept_invitation!
    assert_callbacks_fired :after_invitation_accepted, user
  end

  test 'user.accept_invitation! should not trigger callbacks if validation fails' do
    user = User.invite!(email: 'valid@email.com')
    assert_callbacks_not_fired :after_invitation_accepted, user
    user.username='a'*50
    user.accept_invitation!
    assert_callbacks_not_fired :after_invitation_accepted, user
  end

  test 'user.accept_invitation! should confirm user if confirmable' do
    user = User.invite!(email: 'valid@email.com')
    user.accept_invitation!

    assert user.confirmed?
    refute user.changed?
  end

  test 'user.accept_invitation! should not confirm user if validation fails' do
    user = User.invite!(email: 'valid@email.com')
    user.username='a'*50
    user.accept_invitation!
    user.reload

    refute_predicate user, :confirmed?
  end

  test 'should not send password change notification when accepting invitation' do
    send_password_change_notification = User.send_password_change_notification

    begin
      User.send_password_change_notification = true

      user = User.invite!(email: 'valid@email.com')

      assert_no_difference('ActionMailer::Base.deliveries.size') do
        user.password = user.password_confirmation = '123456789'
        user.accept_invitation!
      end

    ensure
      User.send_password_change_notification = send_password_change_notification
    end
  end

  def assert_callbacks_fired(callback, user)
    assert_callbacks_status callback, user, true
  end

  def assert_callbacks_not_fired(callback, user)
    assert_callbacks_status callback, user, nil
  end

  def assert_callbacks_status(callback, user, fired)
    result = user.send("#{callback}_callback_works".to_sym)
    if fired.nil?
      assert_nil result
    else
      assert_equal fired, result
    end
  end

  test "user.invite! should downcase the class's case_insensitive_keys" do
    # Devise default is :email
    user = User.invite!(email: 'UPPERCASE@email.com')
    assert user.email == 'uppercase@email.com'
  end

  test "user.invite! should strip whitespace from the class's strip_whitespace_keys" do
    # Devise default is email
    user = User.invite!(email: ' valid@email.com ', active: true)
    assert user.email == 'valid@email.com'
    assert user.active == true
  end

  test "user.invite! should trigger callbacks" do
    user = User.new(email: 'valid@email.com')
    assert_callbacks_not_fired :after_invitation_created, user
    user.invite!
    assert_callbacks_fired :after_invitation_created, user
  end

  test 'should pass validation before accept if field is required in post-invited instance' do
    user = User.invite!(email: 'valid@email.com')
    user.testing_accepted_or_not_invited = true
    user.valid?
    assert_empty user.errors
  end

  test 'should fail validation after accept if field is required in post-invited instance' do
    user = User.invite!(email: 'valid@email.com')
    user.testing_accepted_or_not_invited = true
    assert_predicate user, :accept_invitation!
    user = User.where(email: 'valid@email.com').first
    user.valid?
    refute_empty user.errors
  end

  test 'should pass validation after accept if field is required in post-invited instance' do
    user = User.invite!(email: 'valid@email.com')
    user.username = 'test'
    user.testing_accepted_or_not_invited = true
    assert_predicate user, :accept_invitation!
    user = User.where(email: 'valid@email.com').first
    user.bio = "Test"
    user.valid?
    assert_empty user.errors
  end

  test 'should return instance with errors if invitation_token is nil' do
    User.create(email: 'admin@test.com', password: '123456', password_confirmation: '123456')
    user = User.accept_invitation!
    refute_empty user.errors
  end

  test "should count invited, created_by_invite, accepted and not accepted invitations" do
    assert_equal 0, User.invitation_not_accepted.count
    assert_equal 0, User.invitation_accepted.count
    assert_equal 0, User.created_by_invite.count

    User.invite!(email: 'invalid@email.com')
    User.invite!(email: 'another_invalid@email.com')
    user = User.invite!(email: 'valid@email.com')

    assert_equal 3, User.invitation_not_accepted.count
    assert_equal 0, User.invitation_accepted.count
    assert_equal 3, User.created_by_invite.count

    user.accept_invitation!
    assert_equal 2, User.invitation_not_accepted.count
    assert_equal 1, User.invitation_accepted.count
    assert_equal 3, User.created_by_invite.count
  end

  test "should preserve return values of Devise::Recoverable#reset_password" do
    user = new_user
    retval = user.reset_password('anewpassword', 'anewpassword')
    assert_equal true, retval
  end

  test 'should set initial password with variety of characters' do
    PASSWORD_FORMAT = /\A
        (?=.*\d)           # Must contain a digit
        (?=.*[a-z])        # Must contain a lower case character
        (?=.*[A-Z])        # Must contain an upper case character
        (?=.*[[:^alnum:]]) # Must contain a symbol
      /x
    User.stubs(:invite_key).returns(password: PASSWORD_FORMAT)
    Devise.stubs(:friendly_token).returns('onlylowercaseletters')
    user = User.invite!(email: 'valid@email.com')
    assert user.persisted?
    assert user.errors.empty?
  end

  test 'should set initial password following Devise.password_length' do
    user = User.invite!(email: 'valid@email.com')
    assert_empty user.errors
    assert_equal Devise.password_length.last, user.password.length
  end

  test 'should set initial passsword using :validatable with custom password_length' do
    user = Validatable.invite!(email: 'valid@email.com')
    assert_empty user.errors
    assert_equal Validatable.password_length.last, user.password.length
  end
end
