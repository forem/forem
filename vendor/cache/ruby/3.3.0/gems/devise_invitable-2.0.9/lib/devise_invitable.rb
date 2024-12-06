module DeviseInvitable
  autoload :Inviter, 'devise_invitable/inviter'
  autoload :Mailer, 'devise_invitable/mailer'
  autoload :Mapping, 'devise_invitable/mapping'
  autoload :ParameterSanitizer, 'devise_invitable/parameter_sanitizer'
  module Controllers
    autoload :Registrations, 'devise_invitable/controllers/registrations'
    autoload :Helpers, 'devise_invitable/controllers/helpers'
  end
end

require 'devise'
require 'devise_invitable/routes'
require 'devise_invitable/rails'

module Devise
  # Public: Validity period of the invitation token (default: 0). If
  # invite_for is 0 or nil, the invitation will never expire.
  # Set invite_for in the Devise configuration file (in config/initializers/devise.rb).
  #
  #   config.invite_for = 2.weeks # => The invitation token will be valid 2 weeks
  mattr_accessor :invite_for
  @@invite_for = 0

  # Public: Ensure that invited record is valid.
  # The invitation won't be sent if this check fails.
  # (default: false).
  #
  # Examples (in config/initializers/devise.rb)
  #
  #   config.validate_on_invite = true
  mattr_accessor :validate_on_invite
  @@validate_on_invite = false

  # Public: number of invitations the user is allowed to send
  #
  # Examples (in config/initializers/devise.rb)
  #
  #   config.invitation_limit = nil
  mattr_accessor :invitation_limit
  @@invitation_limit = nil

  # Public: The key to be used to check existing users when sending an invitation,
  # and the regexp used to test it when validate_on_invite is not set.
  #
  # Examples (in config/initializers/devise.rb)
  #
  #   config.invite_key = { email: /\A[^@]+@[^@]+\z/ }
  mattr_accessor :invite_key
  @@invite_key = { email: Devise.email_regexp }

  # Public: Resend invitation if user with invited status is invited again
  # (default: true)
  #
  # Example (in config/initializers/devise.rb)
  #
  #   config.resend_invitation = false
  mattr_accessor :resend_invitation
  @@resend_invitation = true

  # Public: The class name of the inviting model. If this is nil,
  # the #invited_by association is declared to be polymorphic. (default: nil)
  mattr_accessor :invited_by_class_name
  @@invited_by_class_name = nil

  # Public: The foreign key to the inviting model (if invited_by_class_name is set)
  # (default: :invited_by_id)
  mattr_accessor :invited_by_foreign_key
  @@invited_by_foreign_key = nil

  # Public: The column name used for counter_cache column. If this is nil,
  # the #invited_by association is declared without counter_cache. (default: nil)
  mattr_accessor :invited_by_counter_cache
  @@invited_by_counter_cache = nil

  # Public: Auto-login after the user accepts the invitation. If this is false,
  # the user will need to manually log in after accepting the invite (default: true).
  mattr_accessor :allow_insecure_sign_in_after_accept
  @@allow_insecure_sign_in_after_accept = true

  # Public: Require password when user accepts the invitation. Set to false if
  # you don't want to ask or enforce to set password while accepting, because is
  # set when user is invited or it will be set later (default: true).
  mattr_accessor :require_password_on_accepting
  @@require_password_on_accepting = true
end

Devise.add_module :invitable, controller: :invitations, model: 'devise_invitable/models', route: { invitation: [nil, :new, :accept] }
