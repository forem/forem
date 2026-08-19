module Users
  # The footer block `layouts/mailer.html.erb` renders at the bottom of DEV's
  # own mail, as plain data, so a Customer.io campaign can render the same
  # thing. Mirrors `Deliverable#layout_message_data`, which supplies the
  # identical keys on the transactional path.
  #
  # Shipped on EVERY trackable event, unconditionally, and never conditionally
  # omitted: Customer.io validates a template's `event.<attr>` references
  # against the triggering event's own schema and fails the ENTIRE body render
  # for an attribute the event does not carry. It fails on the first such
  # reference, so a partial set only moves the error along. A key that is
  # sometimes missing is far worse than one that is sometimes blank.
  #
  # The unsubscribe link is deliberately the same signed, one-click token the
  # SMTP path sends (see `ApplicationMailer#generate_unsubscribe_token`): it
  # flips `users_notification_settings.email_newsletter`, which is what DEV
  # treats as the source of truth and what Core learns from via the
  # `user_newsletter_subscribed` / `_unsubscribed` events. A Customer.io
  # subscription topic would unsubscribe in Customer.io only, leaving DEV
  # believing the person is still subscribed.
  module EmailFooterPayload
    module_function

    BLANK = {
      "signed_up_with_html" => "",
      "unsubscribe_url" => "",
      "notification_settings_url" => ""
    }.freeze

    # 31 days comfortably covers the onboarding drip's 9 day span.
    TOKEN_TTL = 31.days

    def call(user)
      subforem_id = user.onboarding_subforem_id
      host = Subforem.cached_id_to_domain_hash[subforem_id]

      {
        "signed_up_with_html" => ViewContext.new(URL.domain(host), subforem_id).signed_up_with(user),
        "unsubscribe_url" => unsubscribe_url(user, host),
        "notification_settings_url" => URL.url("/settings/notifications", host)
      }
    rescue StandardError => e
      # Never let footer generation take down the Core sync. The keys still
      # ship, blank, so a template referencing them renders rather than failing.
      Rails.logger.warn("EmailFooterPayload failed for user #{user.id}: #{e.message}")
      BLANK.dup
    end

    # Built by concatenation rather than URL.url: the signed token is already
    # percent-escaped by the route helper, and URL.url runs the result through
    # Addressable's #normalize, which unescapes it and corrupts the signature.
    def unsubscribe_url(user, host)
      path = Rails.application.routes.url_helpers
        .email_subscriptions_unsubscribe_path(ut: unsubscribe_token(user))

      "#{URL.url(nil, host)}#{path}"
    end

    def unsubscribe_token(user)
      Rails.application.message_verifier(:unsubscribe).generate({
                                                                  user_id: user.id,
                                                                  email_type: "email_newsletter",
                                                                  expires_at: TOKEN_TTL.from_now.iso8601
                                                                })
    end

    # AuthenticationHelper#signed_up_with needs both the helper and the route
    # helpers; ApplicationController.helpers carries only the former, which is
    # why ApplicationMailer declares them together.
    #
    # The host must be passed in explicitly. Production sets
    # Rails.application.routes.default_url_options to the protocol ALONE
    # (config/environments/production.rb), so new_magic_link_url raises
    # "Missing host to link to!" without it -- while the test and development
    # envs both set a host there, which is exactly why a spec relying on the
    # ambient default cannot catch this. See the spec that stubs the production
    # shape.
    class ViewContext
      include Rails.application.routes.url_helpers
      include ActionView::Helpers::TranslationHelper
      include AuthenticationHelper

      # signed_up_with resolves the community name from `try(:subforem_id)`, so
      # this has to answer to it or the copy says "DEV Community" while the URLs
      # beside it point at the user's own subforem. ApplicationMailer exposes the
      # same reader as a helper_method for exactly this reason.
      attr_reader :subforem_id

      def initialize(host, subforem_id = nil)
        @host = host
        @subforem_id = subforem_id
      end

      def default_url_options
        Rails.application.routes.default_url_options.merge(host: @host)
      end
    end
  end
end
