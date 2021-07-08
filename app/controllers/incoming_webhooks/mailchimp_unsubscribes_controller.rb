module IncomingWebhooks
  class MailchimpUnsubscribesController < ApplicationController
    skip_before_action :verify_authenticity_token

    class InvalidListID < StandardError; end

    LIST_MAPPINGS = {
      mailchimp_newsletter_id: :email_newsletter,
      mailchimp_sustaining_members_id: :email_membership_newsletter,
      mailchimp_tag_moderators_id: :email_tag_mod_newsletter,
      mailchimp_community_moderators_id: :email_community_mod_newsletter
    }.freeze

    def index
      head :ok
    end

    def create
      not_authorized unless valid_secret?
      user = User.find_by!(email: params.dig(:data, :email))
      user.update(email_type => false)
    end

    private

    def valid_secret?
      params[:secret] == Settings::General.mailchimp_incoming_webhook_secret
    end

    def email_type
      list_id = params.dig(:data, :list_id)
      key = LIST_MAPPINGS.keys.detect { |k| Settings::General.public_send(k) == list_id }
      raise InvalidListID unless key

      LIST_MAPPINGS[key]
    end
  end
end
