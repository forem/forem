require 'test_helper'
require 'model_tests_helper'

class InvitationMailTest < ActionMailer::TestCase

  def setup
    setup_mailer
    Devise.mailer_sender = 'test@example.com'
  end

  def user
    @user ||= User.invite!(:email => "valid@email.com")
  end

  def mail
    @mail ||= begin
      user
      ActionMailer::Base.deliveries.last
    end
  end

  test 'email sent after reseting the user password' do
    assert_not_nil mail
  end

  test 'content type should be set to multipart' do
    assert_match /^multipart\/alternative; boundary="[^"]+"; charset=UTF-8/, mail.content_type
  end

  test 'send invitation to the user email' do
    assert_equal [user.email], mail.to
  end

  test 'setup sender from configuration' do
    assert_equal ['test@example.com'], mail.from
  end

  test 'setup subject from I18n' do
    store_translations :en, :devise => { :mailer => { :invitation_instructions => { :subject => 'Localized Invitation' } } } do
      assert_equal 'Localized Invitation', mail.subject
    end
  end

  test 'subject namespaced by model' do
    store_translations :en, :devise => { :mailer => { :invitation_instructions => { :user_subject => 'User Invitation' } } } do
      assert_equal 'User Invitation', mail.subject
    end
  end

  test 'body should have user info' do
    assert_match /#{user.email}/, mail.html_part.body.decoded
    assert_match /#{user.email}/, mail.text_part.body.decoded
  end

  test 'body should have link to confirm the account' do
    host = ActionMailer::Base.default_url_options[:host]
    body = mail.html_part.body.decoded
    invitation_url_regexp = %r{<a href=\"http://#{host}/users/invitation/accept\?invitation_token=#{Thread.current[:token]}">}
    assert_match invitation_url_regexp, body

    body = mail.text_part.body.decoded
    invitation_url_regexp = %r{http://#{host}/users/invitation/accept\?invitation_token=#{Thread.current[:token]}}
    assert_match invitation_url_regexp, body
  end

  test 'body should have link to confirm the account on resend' do
    host = ActionMailer::Base.default_url_options[:host]
    user
    @user = User.find(user.id).invite!
    body = mail.html_part.body.decoded
    invitation_url_regexp = %r{<a href=\"http://#{host}/users/invitation/accept\?invitation_token=#{Thread.current[:token]}">}
    assert_match invitation_url_regexp, body

    body = mail.text_part.body.decoded
    invitation_url_regexp = %r{http://#{host}/users/invitation/accept\?invitation_token=#{Thread.current[:token]}}
    assert_match invitation_url_regexp, body
  end

  test 'body should have invitation due date when it exists' do
    User.stubs(:invite_for => 5)

    host = ActionMailer::Base.default_url_options[:host]
    user
    body = mail.html_part.body.decoded
    due_date_regexp = %r{#{I18n.l user.invitation_due_at, format: :'devise.mailer.invitation_instructions.accept_until_format' }}
    assert_match due_date_regexp, body

    body = mail.text_part.body.decoded
    due_date_regexp = %r{#{I18n.l user.invitation_due_at, format: :'devise.mailer.invitation_instructions.accept_until_format' }}
    assert_match due_date_regexp, body
  end

  test 'options are passed to the delivery method' do
    class CustomMailer < Devise::Mailer
      class << self
        def invitation_instructions(record, name, options = {})
          fail 'Options not as expected' unless options[:invited_at].is_a?(Time)
          new(record, name, options)
        end
      end

      def initialize(*args); end
      def deliver; end
    end
    Devise.mailer = 'InvitationMailTest::CustomMailer'

    User.invite!({ email: 'valid@email.com' }, nil, { invited_at: Time.now })
  end
end
