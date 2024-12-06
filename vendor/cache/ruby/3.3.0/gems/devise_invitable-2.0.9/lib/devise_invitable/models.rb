require 'active_support/deprecation'
require 'devise_invitable/models/authenticatable'

module Devise
  module Models
    # Invitable is responsible for sending invitation emails.
    # When an invitation is sent to an email address, an account is created for it.
    # Invitation email contains a link allowing the user to accept the invitation
    # by setting a password (as reset password from Devise's recoverable module).
    #
    # Configuration:
    #
    #   invite_for: The period the generated invitation token is valid.
    #               After this period, the invited resource won't be able to accept the invitation.
    #               When invite_for is 0 (the default), the invitation won't expire.
    #
    # Examples:
    #
    #   User.find(1).invited_to_sign_up?                    # => true/false
    #   User.invite!(email: 'someone@example.com')          # => send invitation
    #   User.accept_invitation!(invitation_token: '...')    # => accept invitation with a token
    #   User.find(1).accept_invitation!                     # => accept invitation
    #   User.find(1).invite!                                # => reset invitation status and send invitation again
    module Invitable
      extend ActiveSupport::Concern

      attr_accessor :skip_invitation
      attr_accessor :completing_invite
      attr_reader   :raw_invitation_token

      included do
        include ::DeviseInvitable::Inviter
        belongs_to_options = if Devise.invited_by_class_name
          { class_name: Devise.invited_by_class_name }
        else
          { polymorphic: true }
        end
        if fk = Devise.invited_by_foreign_key
          belongs_to_options[:foreign_key] = fk
        end
        if defined?(ActiveRecord) && defined?(ActiveRecord::Base) && self < ActiveRecord::Base
          counter_cache = Devise.invited_by_counter_cache
          belongs_to_options.merge! counter_cache: counter_cache if counter_cache
          belongs_to_options.merge! optional: true if ActiveRecord::VERSION::MAJOR >= 5
        elsif defined?(Mongoid) && defined?(Mongoid::Document) && self < Mongoid::Document && Mongoid::VERSION >= '6.0.0'
          belongs_to_options.merge! optional: true
        end
        belongs_to :invited_by, **belongs_to_options

        extend ActiveModel::Callbacks
        define_model_callbacks :invitation_created
        define_model_callbacks :invitation_accepted

        scope :no_active_invitation, lambda { where(invitation_token: nil) }
        if defined?(Mongoid) && defined?(Mongoid::Document) && self < Mongoid::Document
          scope :created_by_invite, lambda { where(:invitation_created_at.ne => nil) }
          scope :invitation_not_accepted, lambda { where(invitation_accepted_at: nil, :invitation_token.ne => nil) }
          scope :invitation_accepted, lambda { where(:invitation_accepted_at.ne => nil) }
        else
          scope :created_by_invite, lambda { where(arel_table[:invitation_created_at].not_eq(nil)) }
          scope :invitation_not_accepted, lambda { where(arel_table[:invitation_token].not_eq(nil)).where(invitation_accepted_at: nil) }
          scope :invitation_accepted, lambda { where(arel_table[:invitation_accepted_at].not_eq(nil)) }

          callbacks = [
            :before_invitation_created,
            :after_invitation_created,
            :before_invitation_accepted,
            :after_invitation_accepted,
          ]

          callbacks.each do |callback_method|
            send callback_method
          end
        end
      end

      def self.required_fields(klass)
        fields = [:invitation_token, :invitation_created_at, :invitation_sent_at, :invitation_accepted_at,
         :invitation_limit, Devise.invited_by_foreign_key || :invited_by_id, :invited_by_type]
        fields << :invitations_count if defined?(ActiveRecord) && self < ActiveRecord::Base
        fields -= [:invited_by_type] if Devise.invited_by_class_name
        fields
      end

      # Accept an invitation by clearing invitation token and and setting invitation_accepted_at
      def accept_invitation
        self.invitation_accepted_at = Time.now.utc
        self.invitation_token = nil
      end

      # Accept an invitation by clearing invitation token and and setting invitation_accepted_at
      # Saves the model and confirms it if model is confirmable, running invitation_accepted callbacks
      def accept_invitation!
        if self.invited_to_sign_up?
          @accepting_invitation = true
          run_callbacks :invitation_accepted do
            self.accept_invitation
            self.confirmed_at ||= self.invitation_accepted_at if self.respond_to?(:confirmed_at=)
            self.save
          end.tap do |saved|
            self.rollback_accepted_invitation if !saved
            @accepting_invitation = false
          end
        end
      end

      def rollback_accepted_invitation
        self.invitation_token = self.invitation_token_was
        self.invitation_accepted_at = nil
        self.confirmed_at = nil if self.respond_to?(:confirmed_at=)
      end

      # Verify wheather a user is created by invitation, irrespective to invitation status
      def created_by_invite?
        invitation_created_at.present?
      end

      # Verifies whether a user has been invited or not
      def invited_to_sign_up?
        accepting_invitation? || (persisted? && invitation_token.present?)
      end

      # Returns true if accept_invitation! was called
      def accepting_invitation?
        @accepting_invitation
      end

      # Verifies whether a user accepted an invitation (false when user is accepting it)
      def invitation_accepted?
        !accepting_invitation? && invitation_accepted_at.present?
      end

      # Verifies whether a user has accepted an invitation (false when user is accepting it), or was never invited
      def accepted_or_not_invited?
        invitation_accepted? || !invited_to_sign_up?
      end

      # Reset invitation token and send invitation again
      def invite!(invited_by = nil, options = {})
        # This is an order-dependant assignment, this can't be moved
        was_invited = invited_to_sign_up?

        # Required to workaround confirmable model's confirmation_required? method
        # being implemented to check for non-nil value of confirmed_at
        if new_record_and_responds_to?(:confirmation_required?)
          def self.confirmation_required?; false; end
        end

        yield self if block_given?
        generate_invitation_token if no_token_present_or_skip_invitation?

        run_callbacks :invitation_created do
          self.invitation_created_at = Time.now.utc
          self.invitation_sent_at = self.invitation_created_at unless skip_invitation
          self.invited_by = invited_by if invited_by

          # Call these before_validate methods since we aren't validating on save
          self.downcase_keys if new_record_and_responds_to?(:downcase_keys)
          self.strip_whitespace if new_record_and_responds_to?(:strip_whitespace)

          validate = options.key?(:validate) ? options[:validate] : self.class.validate_on_invite
          if save(validate: validate)
            self.invited_by.decrement_invitation_limit! if !was_invited and self.invited_by.present?
            deliver_invitation(options) unless skip_invitation
          end
        end
      end

      # Verify whether a invitation is active or not. If the user has been
      # invited, we need to calculate if the invitation time has not expired
      # for this user, in other words, if the invitation is still valid.
      def valid_invitation?
        invited_to_sign_up? && invitation_period_valid?
      end

      # Only verify password when is not invited
      def valid_password?(password)
        super unless !accepting_invitation? && block_from_invitation?
      end

      # Prevent password changed email when accepting invitation
      def send_password_change_notification?
        super && !accepting_invitation?
      end

      # Enforce password when invitation is being accepted
      def password_required?
        (accepting_invitation? && self.class.require_password_on_accepting) || super
      end

      def unauthenticated_message
        block_from_invitation? ? :invited : super
      end

      def clear_reset_password_token
        reset_password_token_present = reset_password_token.present?
        super
        accept_invitation! if reset_password_token_present && valid_invitation?
      end

      def clear_errors_on_valid_keys
        self.class.invite_key.each do |key, value|
          self.errors.delete(key) if value === self.send(key)
        end
      end

      # Deliver the invitation email
      def deliver_invitation(options = {})
        generate_invitation_token! unless @raw_invitation_token
        self.update_attribute :invitation_sent_at, Time.now.utc unless self.invitation_sent_at
        send_devise_notification(:invitation_instructions, @raw_invitation_token, options)
      end

      # provide alias to the encrypted invitation_token stored by devise
      def encrypted_invitation_token
        self.invitation_token
      end

      def confirmation_required_for_invited?
        respond_to?(:confirmation_required?, true) && confirmation_required?
      end

      def invitation_due_at
        return nil if (self.class.invite_for == 0 || self.class.invite_for.nil?)
        #return nil unless self.class.invite_for

        time = self.invitation_created_at || self.invitation_sent_at
        time + self.class.invite_for
      end

      def add_taken_error(key)
        errors.add(key, :taken)
      end

      def invitation_taken?
        !invited_to_sign_up?
      end

      protected

        def block_from_invitation?
          invited_to_sign_up?
        end

        # Checks if the invitation for the user is within the limit time.
        # We do this by calculating if the difference between today and the
        # invitation sent date does not exceed the invite for time configured.
        # Invite_for is a model configuration, must always be an integer value.
        #
        # Example:
        #
        #   # invite_for = 1.day and invitation_sent_at = today
        #   invitation_period_valid?   # returns true
        #
        #   # invite_for = 5.days and invitation_sent_at = 4.days.ago
        #   invitation_period_valid?   # returns true
        #
        #   # invite_for = 5.days and invitation_sent_at = 5.days.ago
        #   invitation_period_valid?   # returns false
        #
        #   # invite_for = nil
        #   invitation_period_valid?   # will always return true
        #
        def invitation_period_valid?
          time = invitation_created_at || invitation_sent_at
          self.class.invite_for.to_i.zero? || (time && time.utc >= self.class.invite_for.ago)
        end

        # Generates a new random token for invitation, and stores the time
        # this token is being generated
        def generate_invitation_token
          raw, enc = Devise.token_generator.generate(self.class, :invitation_token)
          @raw_invitation_token = raw
          self.invitation_token = enc
        end

        def generate_invitation_token!
          generate_invitation_token && save(validate: false)
        end

        def new_record_and_responds_to?(method)
          self.new_record? && self.respond_to?(method, true)
        end

        def no_token_present_or_skip_invitation?
          self.invitation_token.nil? || (!skip_invitation || @raw_invitation_token.nil?)
        end

      module ClassMethods
        # Return fields to invite
        def invite_key_fields
          invite_key.keys
        end

        # Attempt to find a user by its email. If a record is not found,
        # create a new user and send an invitation to it. If the user is found,
        # return the user with an email already exists error.
        # If the user is found and still has a pending invitation, invitation
        # email is resent unless resend_invitation is set to false.
        # Attributes must contain the user's email, other attributes will be
        # set in the record
        def _invite(attributes = {}, invited_by = nil, options = {}, &block)
          invite_key_array = invite_key_fields
          attributes_hash = {}
          invite_key_array.each do |k,v|
            attribute = attributes.delete(k)
            attribute = attribute.to_s.strip if strip_whitespace_keys.include?(k)
            attributes_hash[k] = attribute
          end

          invitable = find_or_initialize_with_errors(invite_key_array, attributes_hash)
          invitable.assign_attributes(attributes)
          invitable.invited_by = invited_by
          unless invitable.password || invitable.encrypted_password.present?
            invitable.password = random_password
          end

          invitable.valid? if self.validate_on_invite
          if invitable.new_record?
            invitable.clear_errors_on_valid_keys if !self.validate_on_invite
          elsif invitable.invitation_taken? || !self.resend_invitation
            invite_key_array.each do |key|
              invitable.add_taken_error(key)
            end
          end

          yield invitable if block_given?
          mail = invitable.invite!(nil, options.merge(validate: false)) if invitable.errors.empty?
          [invitable, mail]
        end

        def invite!(attributes = {}, invited_by = nil, options = {}, &block)
          attr_hash = ActiveSupport::HashWithIndifferentAccess.new(attributes.to_h)
          _invite(attr_hash, invited_by, options, &block).first
        end

        def invite_mail!(attributes = {}, invited_by = nil, options = {}, &block)
          _invite(attributes, invited_by, options, &block).last
        end

        # Attempt to find a user by it's invitation_token to set it's password.
        # If a user is found, reset it's password and automatically try saving
        # the record. If not user is found, returns a new user containing an
        # error in invitation_token attribute.
        # Attributes must contain invitation_token, password and confirmation
        def accept_invitation!(attributes = {})
          original_token = attributes.delete(:invitation_token)
          invitable = find_by_invitation_token(original_token, false)
          if invitable.errors.empty?
            invitable.assign_attributes(attributes)
            invitable.accept_invitation!
          end
          invitable
        end

        def find_by_invitation_token(original_token, only_valid)
          invitation_token = Devise.token_generator.digest(self, :invitation_token, original_token)

          invitable = find_or_initialize_with_error_by(:invitation_token, invitation_token)
          invitable.errors.add(:invitation_token, :invalid) if invitable.invitation_token && invitable.persisted? && !invitable.valid_invitation?
          invitable unless only_valid && invitable.errors.present?
        end

        # Callback convenience methods
        def before_invitation_created(*args, &blk)
          set_callback(:invitation_created, :before, *args, &blk)
        end

        def after_invitation_created(*args, &blk)
          set_callback(:invitation_created, :after, *args, &blk)
        end

        def before_invitation_accepted(*args, &blk)
          set_callback(:invitation_accepted, :before, *args, &blk)
        end

        def after_invitation_accepted(*args, &blk)
          set_callback(:invitation_accepted, :after, *args, &blk)
        end


        Devise::Models.config(self, :invite_for)
        Devise::Models.config(self, :validate_on_invite)
        Devise::Models.config(self, :invitation_limit)
        Devise::Models.config(self, :invite_key)
        Devise::Models.config(self, :resend_invitation)
        Devise::Models.config(self, :invited_by_class_name)
        Devise::Models.config(self, :invited_by_foreign_key)
        Devise::Models.config(self, :invited_by_counter_cache)
        Devise::Models.config(self, :allow_insecure_sign_in_after_accept)
        Devise::Models.config(self, :require_password_on_accepting)

        private

          # The random password, as set after an invitation, must conform
          # to any password format validation rules of the application.
          # This default fixes the most common scenarios: Passwords must contain
          # lower + upper case, a digit and a symbol.
          # For more unusual rules, this method can be overridden.
          def random_password
            length = respond_to?(:password_length) ? password_length : Devise.password_length

            prefix = 'aA1!'
            prefix + Devise.friendly_token(length.last - prefix.length)
          end
      end
    end
  end
end
