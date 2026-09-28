module Ai
  ##
  # A cheap Jev pass that decides whether an article or comment without links should still go
  # to the full spam check (Ai::ArticleCheck / Ai::CommentCheck), which makes the final call on
  # whichever model it is configured for. It only escalates: a "yes" here never flags anything
  # on its own.
  #
  # Runs only when the :spam_escalation function is set to Jev (see Ai::FunctionConfig);
  # otherwise content without links is never escalated, as before.
  class SpamEscalationCheck
    VERSION = "1.1".freeze
    FUNCTION_KEY = :spam_escalation

    MAX_TEXT_LENGTH = 3_000

    QUESTIONS = {
      spam: Ai::TypeSafe::Questions.noul(
        "Is `content`, published on a developer community, spam?",
        yes: "Advertising, SEO or affiliate content, selling goods, services or accounts, scams, or gibberish, " \
             "rather than a good-faith contribution to the community.",
        no: "A good-faith post for developers, even if it mentions the author's own project.",
      ),
      offplatform_contact: Ai::TypeSafe::Questions.noul(
        "Does `content` ask readers to contact someone off this platform to buy, order, or get a service?",
        yes: "It gives a Telegram, WhatsApp, Discord, phone number, email, or similar contact for readers " \
             "to buy, order, or get a service.",
        no: "It makes no such request.",
      )
    }.freeze

    # @param text [String] the content to check
    # @param content [Article, Comment] the record the text came from (for the audit log)
    def initialize(text:, content:)
      @text = text.to_s.first(MAX_TEXT_LENGTH)
      @content = content
    end

    # @return [Boolean] true if the content should go to the full spam check
    def escalate?
      selection = Ai::FunctionConfig.selection_for(FUNCTION_KEY)
      return false unless selection.jev?

      client = Ai::TypeSafe::Client.new(model: selection.model, wrapper: self, affected_content: @content,
                                        affected_user: @content.user, **Ai::TypeSafe::Client::FAIL_FAST)
      result = client.evaluate(state: { content: @text }, questions: QUESTIONS)
      QUESTIONS.keys.any? { |id| result.noul(id) >= threshold }
    rescue StandardError => e
      Rails.logger.error("Spam escalation check failed: #{e}")
      false
    end

    private

    # Admin-tunable (Settings::AiFunctions). The default favors recall, since a false escalation
    # only costs one spam check. Tune it from the probabilities logged in AiAudit against which
    # escalations the spam check confirms.
    def threshold
      Settings::AiFunctions.global_spam_escalation_threshold
    end
  end
end
