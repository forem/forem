module Ai
  ##
  # A cheap first pass (Jev) that decides whether content without links should still be sent
  # to the Gemini spam checks (ArticleCheck / CommentCheck). It only escalates: a "yes" here
  # never flags anything on its own. Without TYPESAFE_API_KEY it never escalates.
  class SpamEscalationCheck
    VERSION = "1.0".freeze

    # ponytail: fixed threshold that favors recall, since a false escalation only costs one
    # Gemini call. Tune it from the probabilities logged in AiAudit.
    THRESHOLD = 0.3
    MAX_TEXT_LENGTH = 3_000

    QUESTIONS = {
      spam: {
        type: "noul",
        instructions: "Is this post, published on a developer community, spam?",
        criteria: {
          "true" => "Spam: advertising, SEO or affiliate content, selling goods, services or accounts, " \
                    "scams, or gibberish, rather than a good-faith contribution to the community.",
          "false" => "A good-faith post for developers, even if it mentions the author's own project."
        }
      },
      offplatform_contact: {
        type: "noul",
        instructions: "Does the post ask readers to contact someone off this platform to buy, order, or get a service?",
        criteria: {
          "true" => "It gives a Telegram, WhatsApp, Discord, phone number, email, or similar contact " \
                    "for readers to buy, order, or get a service.",
          "false" => "It makes no such request."
        }
      }
    }.freeze

    def self.enabled?
      Ai::Jev::DEFAULT_KEY.present?
    end

    # @param text [String] the content to check
    # @param content [Article, Comment] the record the text came from (for the audit log)
    def initialize(text:, content:)
      @text = text.to_s.first(MAX_TEXT_LENGTH)
      @content = content
    end

    # @return [Boolean] true if the content should go to the Gemini spam check
    def escalate?
      return false unless self.class.enabled?

      answers = Ai::Jev.new(wrapper: self, affected_content: @content, affected_user: @content.user)
        .call(state: @text, questions: QUESTIONS)
      QUESTIONS.keys.any? { |id| answers.dig(id.to_s, "noul").to_f >= THRESHOLD }
    rescue StandardError => e
      Rails.logger.error("Spam escalation check failed: #{e}")
      false
    end
  end
end
