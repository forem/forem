module Ai
  ##
  # Analyzes an article, comment, or profile from a low-trust account to determine if it is
  # attempting to get users to sign up, log in, or verify their account, especially when
  # impersonating the platform, its support team, or staff.
  #
  # Normalizes Unicode compatibility characters (such as Mathematical Sans-Serif Bold Italic)
  # and Cyrillic/Greek homoglyphs before analysis so obfuscated text like
  # "𝙈𝙖𝙣𝙙𝙖𝙩𝙤𝙧𝙮 𝙪𝙨𝙚𝙧 𝙫𝙚𝙧𝙞𝙛𝙞𝙘𝙖𝙩𝙞𝙤𝙣" or "𝘿𝙚𝙫 𝙎𝙪𝙥𝙥𝙤𝙧𝙩 𝙏𝙚𝙖𝙢" is clearly exposed.
  #
  # Supports both Gemini and TypeSafe Jev via Ai::FunctionConfig (:phishing_signup_check).
  class PhishingSignupCheck
    include Ai::TypeSafe::Questions

    VERSION = "1.0".freeze
    FUNCTION_KEY = :phishing_signup_check

    CLEAR = 0.85
    SUPPORTING = 0.5
    JEV_BODY_CHARS = 8_000

    # Common Cyrillic and Greek lookalike characters used in homoglyph phishing attacks.
    CONFUSABLE_CHARS = {
      "А" => "A", "В" => "B", "Е" => "E", "Ѕ" => "S", "І" => "I", "Ј" => "J",
      "К" => "K", "М" => "M", "Н" => "H", "О" => "O", "Р" => "P", "С" => "C",
      "Т" => "T", "У" => "Y", "Х" => "X", "а" => "a", "в" => "b", "е" => "e",
      "ѕ" => "s", "і" => "i", "ј" => "j", "к" => "k", "м" => "m", "н" => "h",
      "о" => "o", "р" => "p", "с" => "c", "т" => "t", "у" => "y", "х" => "x",
      "Α" => "A", "Β" => "B", "Ε" => "E", "Ζ" => "Z", "Η" => "H", "Ι" => "I",
      "Κ" => "K", "Μ" => "M", "Ν" => "N", "Ο" => "O", "Ρ" => "P", "Τ" => "T",
      "Υ" => "Y", "Χ" => "X", "α" => "a", "ο" => "o", "ρ" => "p", "υ" => "u"
    }.freeze
    CONFUSABLE_REGEXP = Regexp.union(CONFUSABLE_CHARS.keys).freeze
    ZERO_WIDTH_REGEXP = /[\u200B-\u200D\uFEFF\u00AD\u034F\u2060]/
    OBFUSCATED_UNICODE_REGEXP = /[\u{1D400}-\u{1D7FF}\uFF01-\uFF5E\u2460-\u24FF]/
    MIXED_SCRIPT_WORD_REGEXP = /[A-Za-z]\S*[\p{Cyrillic}\p{Greek}]|[\p{Cyrillic}\p{Greek}]\S*[A-Za-z]/

    def self.normalize_obfuscated_text(text)
      return "" if text.blank?

      text.to_s
        .gsub(ZERO_WIDTH_REGEXP, "")
        .unicode_normalize(:nfkc)
        .gsub(CONFUSABLE_REGEXP, CONFUSABLE_CHARS)
    end

    def self.unicode_obfuscated?(text)
      return false if text.blank?

      str = text.to_s
      str.match?(OBFUSCATED_UNICODE_REGEXP) || str.match?(MIXED_SCRIPT_WORD_REGEXP)
    end

    # @param record [Article, Comment, User] The record to check.
    def initialize(record)
      @record = record
      @user = record.is_a?(User) ? record : record.user
      @selection = Ai::FunctionConfig.selection_for(FUNCTION_KEY)
      return if @selection.jev?

      affected_content = record.is_a?(User) ? nil : record
      @ai_client = Ai::Base.new(model: @selection.gemini_model, wrapper: self, affected_user: @user,
                                affected_content: affected_content)
    end

    # @return [Boolean] true if the record is phishing, platform impersonation, or low-trust signup spam.
    def spam?
      return spam_via_jev? if @selection.jev?

      response = @ai_client.call(build_prompt)
      parse_response(response)
    rescue Ai::Base::ProhibitedContentError
      raise unless @record.is_a?(Comment)

      spam_in_isolation?
    rescue StandardError => e
      Rails.logger.error("Phishing/Signup Spam Check failed: #{e}")
      false
    end

    private

    def spam_in_isolation?
      parse_response(@ai_client.call(<<~PROMPT))
        Is the following comment or author identity CLEARLY phishing, platform impersonation, or deceptive signup spam? Answer only with YES or NO.
        ---
        Author Name: #{normalized_author_name}
        Author Username: #{@user&.username}
        Comment: #{normalized_body}
      PROMPT
    rescue Ai::Base::ProhibitedContentError
      raise
    rescue StandardError => e
      Rails.logger.error("Phishing/Signup Spam Check in isolation failed: #{e}")
      false
    end

    # --- Jev (TypeSafe System One) ---

    def spam_via_jev?
      affected_content = @record.is_a?(User) ? nil : @record
      client = Ai::TypeSafe::Client.new(model: @selection.model, wrapper: self, affected_user: @user,
                                        affected_content: affected_content, **Ai::TypeSafe::Client::FAIL_FAST)
      result = client.evaluate(state: jev_state, questions: jev_questions)
      spam_from_jev?(result)
    end

    def jev_state
      state = {
        community: {
          name: community_name,
          description: community_description.presence || "Developer community platform."
        },
        author: jev_author_state,
        record_type: record_type
      }

      case @record
      when Article
        state[:content] = jev_article_state
      when Comment
        state[:content] = jev_comment_state
        state[:parent_post] = jev_parent_post_state if @record.commentable
      end

      state
    end

    def jev_author_state
      {
        name: @user&.name.to_s,
        normalized_name: normalized_author_name,
        username: @user&.username.to_s,
        summary: @user&.profile&.summary.to_s,
        normalized_summary: normalized_author_summary,
        website_url: @user&.profile&.website_url.to_s,
        unicode_obfuscation_detected: author_obfuscated?
      }
    end

    def jev_article_state
      {
        title: @record.title.to_s,
        normalized_title: normalized_title,
        body: @record.body_markdown.to_s.truncate(JEV_BODY_CHARS),
        normalized_body: normalized_body.truncate(JEV_BODY_CHARS),
        unicode_obfuscation_detected: content_obfuscated?
      }
    end

    def jev_comment_state
      {
        body: @record.body_markdown.to_s.truncate(4_000),
        normalized_body: normalized_body.truncate(4_000),
        unicode_obfuscation_detected: content_obfuscated?
      }
    end

    def jev_parent_post_state
      post = @record.commentable
      title = post.respond_to?(:title) ? post.title.to_s : ""
      body = post.respond_to?(:body_markdown) ? post.body_markdown.to_s : ""
      {
        title: title,
        normalized_title: self.class.normalize_obfuscated_text(title),
        body: body.truncate(1_500),
        normalized_body: self.class.normalize_obfuscated_text(body).truncate(1_500)
      }
    end

    def jev_questions
      {
        platform_impersonation: noul(
          {
            question: "Does `author` (or `content`) falsely impersonate the platform " \
                      "(`community.name` / DEV / Forem), its support team, moderators, security team, " \
                      "or an official system/verification bot?",
            focus: "Check both raw and `normalized_*` fields, since attackers frequently disguise names like " \
                   "'Dev Support Team' or 'Support Bot' with Unicode math fonts or Cyrillic lookalike characters."
          },
          yes: "It poses as official platform support, staff, administration, security, verification bot, or helpdesk.",
          no: "A regular user, developer, project, or company using their own identity without claiming " \
              "to be official platform staff.",
        ),
        phishing_or_verification_lure: noul(
          {
            question: "Does `content` (or `parent_post` when `author` is mass-mentioning users in a comment) try to " \
                      "trick users into verifying their account, logging in, confirming identity, or clicking a " \
                      "link/short-URL under threat of account restriction or suspension?",
            focus: "Look for mandatory verification notices, login lures, credential harvesting, or puppet comments " \
                   "that exist to @-mention users into a phishing or verification scam post."
          },
          yes: "It pressures or directs users to verify, log in, authenticate, or visit an external/short link " \
               "to keep account access, or tags users to draw them into such a lure.",
          no: "Normal technical discussion, tutorials about authentication/verification, " \
              "or genuine community interaction.",
        ),
        suspicious_signup_solicitation: noul(
          {
            question: "Is this low-trust account primarily attempting to get people to sign up, register, join, " \
                      "or log in to an external site, campaign, giveaway, or dubious service in a spammy " \
                      "or deceptive way?",
            focus: "Distinguish deceptive or spammy signup/registration solicitation from a developer sharing a " \
                   "legitimate project or technical write-up."
          },
          yes: "It exists mainly to funnel readers into signing up, registering, or logging in (especially " \
               "via short links, fake announcements, referral traps, or mass-mentioning), offering no genuine " \
               "community contribution.",
          no: {
            what: "A genuine technical post, question, comment, or normal developer profile.",
            includes: "An honest Show DEV / project launch post that explains what was built, " \
                      "or a tutorial discussing signup flows."
          },
        ),
        good_faith_contribution: noul(
          "Is this a good-faith developer contribution, discussion, or legitimate user profile rather than " \
          "impersonation, phishing, or signup spam?",
        )
      }
    end

    def spam_from_jev?(result)
      impersonation = result.noul(:platform_impersonation)
      phishing = result.noul(:phishing_or_verification_lure)
      signup_spam = result.noul(:suspicious_signup_solicitation)
      good_faith = result.noul(:good_faith_contribution)

      return true if impersonation >= CLEAR
      return true if phishing >= CLEAR
      return true if impersonation >= SUPPORTING && [phishing, signup_spam].max >= SUPPORTING
      return true if signup_spam >= CLEAR && good_faith < SUPPORTING

      false
    end

    # --- Gemini ---

    def build_prompt
      <<~PROMPT
        Analyze the following low-trust account activity for phishing, platform impersonation, or deceptive signup/login solicitation.
        Your answer must be a single word: YES or NO.

        Primary Task: Determine if this low-trust account is CLEARLY attempting to:
        1. Impersonate the platform (#{community_name} / DEV / Forem), its support team, staff, moderators, or an official verification/security bot (including via Unicode stylized fonts or Cyrillic/Greek homoglyph characters like "𝘿𝙚𝙫 𝙎𝙪𝙥𝙥𝙤𝙧𝙩 𝙏𝙚𝙖𝙢" or "Suрроrt Воt").
        2. Phish users or trick them into "verifying" their account, logging in, or clicking an external/shortened URL (such as tr.ee, bit.ly, etc.) under threat of account suspension or restricted access (e.g., "Mandatory user verification").
        3. Use puppet comments (such as lists of @-mentions) while impersonating support/staff or on a phishing/verification post to summon victims.
        4. Solicit users to sign up, register, or log in to a deceptive, promotional, or spammy external thing without genuine community value.

        Do NOT flag genuine developer posts, legitimate project launches (Show DEV) where a developer shares an app they built in good faith, or technical tutorials about authentication/signup flows.

        1. **Community Context**:
           ---
           Community Name: #{community_name}
           Description: #{community_description.presence || 'Developer community platform.'}
           ---

        2. **Author Profile Context (Low-Trust Account)**:
           ---
           Name: #{@user&.name}
           Normalized Name: #{normalized_author_name}
           Username: @#{@user&.username}
           Bio/Summary: #{@user&.profile&.summary}
           Normalized Bio/Summary: #{normalized_author_summary}
           Website URL: #{@user&.profile&.website_url}
           Unicode/Homoglyph Obfuscation in Profile: #{author_obfuscated? ? 'YES' : 'NO'}
           ---

        #{content_prompt_section}

        Based on all the context above, is this low-trust account CLEARLY engaging in platform impersonation, phishing/verification lures, or spammy signup/login solicitation? Answer only with YES or NO.
      PROMPT
    end

    def content_prompt_section
      case @record
      when Article
        <<~SECTION
          3. **ARTICLE TO CHECK**:
             ---
             Title: #{@record.title}
             Normalized Title: #{normalized_title}
             Unicode/Homoglyph Obfuscation in Content: #{content_obfuscated? ? 'YES' : 'NO'}
             Body:
             #{@record.body_markdown.to_s.first(JEV_BODY_CHARS)}
             Normalized Body:
             #{normalized_body.first(JEV_BODY_CHARS)}
             ---
        SECTION
      when Comment
        post = @record.commentable
        parent_title = post.respond_to?(:title) ? post.title.to_s : ""
        parent_body = post.respond_to?(:body_markdown) ? post.body_markdown.to_s.first(1_500) : ""
        <<~SECTION
          3. **PARENT POST CONTEXT**:
             ---
             Title: #{parent_title}
             Normalized Title: #{self.class.normalize_obfuscated_text(parent_title)}
             Body: #{parent_body}
             Normalized Body: #{self.class.normalize_obfuscated_text(parent_body)}
             ---

          4. **COMMENT TO CHECK**:
             ---
             Unicode/Homoglyph Obfuscation in Comment: #{content_obfuscated? ? 'YES' : 'NO'}
             Comment Body:
             #{@record.body_markdown.to_s.first(4_000)}
             Normalized Comment Body:
             #{normalized_body.first(4_000)}
             ---
        SECTION
      else
        <<~SECTION
          3. **RECORD TYPE**: Profile check only.
        SECTION
      end
    end

    def parse_response(response)
      !response.nil? && response.strip.upcase == "YES"
    end

    def record_type
      case @record
      when Article then "article"
      when Comment then "comment"
      else "profile"
      end
    end

    def community_name
      Settings::Community.community_name.presence || "DEV Community"
    end

    def community_description
      subforem_id = @record.respond_to?(:subforem_id) ? @record.subforem_id : Subforem.cached_default_id
      Settings::RateLimit.internal_content_description_spec(subforem_id: subforem_id).presence ||
        Settings::Community.community_description(subforem_id: subforem_id)
    end

    def normalized_author_name
      @normalized_author_name ||= self.class.normalize_obfuscated_text(@user&.name)
    end

    def normalized_author_summary
      @normalized_author_summary ||= self.class.normalize_obfuscated_text(@user&.profile&.summary)
    end

    def normalized_title
      @normalized_title ||= self.class.normalize_obfuscated_text(@record.respond_to?(:title) ? @record.title : "")
    end

    def normalized_body
      @normalized_body ||= self.class.normalize_obfuscated_text(
        @record.respond_to?(:body_markdown) ? @record.body_markdown : "",
      )
    end

    def author_obfuscated?
      self.class.unicode_obfuscated?(@user&.name) ||
        self.class.unicode_obfuscated?(@user&.profile&.summary)
    end

    def content_obfuscated?
      (@record.respond_to?(:title) && self.class.unicode_obfuscated?(@record.title)) ||
        (@record.respond_to?(:body_markdown) && self.class.unicode_obfuscated?(@record.body_markdown))
    end
  end
end
