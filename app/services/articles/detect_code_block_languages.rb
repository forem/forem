require "json"

module Articles
  #
  # When the :code_block_language_detection function is set to Jev (see Ai::FunctionConfig),
  # each unlabeled block gets its own TypeSafe Choice over the supported Rouge tags. Each block
  # is its own small state, so other blocks never act as distractors, and low-confidence
  # answers fall back to "plaintext".
  class DetectCodeBlockLanguages
    include Ai::TypeSafe::Questions

    VERSION = "1.1".freeze
    FUNCTION_KEY = :code_block_language_detection
    # Similar languages (e.g. javascript/jsx/typescript) legitimately share probability, so the
    # bar is low; below it plain text is the safer rendering.
    MIN_JEV_CONFIDENCE = 0.3
    FENCED_CODE_BLOCK_REGEX = /
      (?<leading>\A|\n)
      (?<indent>[ ]{0,3})
      (?<fence>`{3,}|~{3,})
      (?<info>[^\n]*)
      \n
      (?<code>.*?)
      \n
      \k<indent>\k<fence>(?<closing_whitespace>[ \t]*)
      (?=\n|\z)
    /mx.freeze
    MAX_BLOCK_CHARS = 2_000
    SUPPORTED_LANGUAGE_TAGS = (Rouge::Lexer.all.filter_map(&:tag) + ["plaintext"]).uniq.sort.freeze

    def self.call(article)
      new(article).call
    end

    def self.contains_unlabeled_code_blocks?(markdown)
      markdown.to_s.to_enum(:scan, FENCED_CODE_BLOCK_REGEX).any? do
        Regexp.last_match[:info].to_s.strip.blank?
      end
    end

    # Rouge tag => human-readable name for the Jev Choice options, e.g. "ruby" => "Ruby".
    def self.language_criteria
      @language_criteria ||= begin
        titles = Rouge::Lexer.all.each_with_object({}) { |lexer, memo| memo[lexer.tag] ||= lexer.title if lexer.tag }
        SUPPORTED_LANGUAGE_TAGS.index_with do |tag|
          tag == "plaintext" ? "Plain text, console output, or no specific language" : titles[tag] || tag
        end
      end
    end

    def initialize(article, ai_client: nil)
      @article = article
      @ai_client = ai_client
    end

    def call
      return false if article.blank? || article.body_markdown.blank? || article.user.blank?

      unlabeled_blocks = extract_unlabeled_blocks
      return false if unlabeled_blocks.blank?
      return false if ai_client_unconfigured?

      detected_languages = if use_jev?
                             detect_languages_via_jev(unlabeled_blocks)
                           else
                             parse_response(ai_client.call(build_prompt(unlabeled_blocks)), unlabeled_blocks.count)
                           end
      updated_markdown = apply_languages(detected_languages)
      return false if updated_markdown == article.body_markdown

      result = ContentRenderer.new(updated_markdown, source: article, user: article.user).process_article
      article.update_columns(body_markdown: updated_markdown, processed_html: result.processed_html,
                             reading_time: result.reading_time)
      true
    rescue StandardError => e
      Rails.logger.error("Code block language detection failed for article #{article.id}: #{e}")
      false
    end

    private

    attr_reader :ai_client, :article

    def ai_client
      @ai_client ||= Ai::Base.new(model: selection.gemini_model(Ai::Base::DEFAULT_LITE_MODEL), wrapper: self,
                                  affected_content: article, affected_user: article.user)
    end

    def selection
      @selection ||= Ai::FunctionConfig.selection_for(FUNCTION_KEY)
    end

    # An injected client always wins so callers and specs can force the Gemini path.
    def use_jev?
      @ai_client.blank? && selection.jev?
    end

    def ai_client_unconfigured?
      @ai_client.blank? && !Ai::FunctionConfig.available?(FUNCTION_KEY)
    end

    # --- Jev (TypeSafe System One) ---

    def detect_languages_via_jev(unlabeled_blocks)
      client = Ai::TypeSafe::Client.new(model: selection.model, wrapper: self, affected_content: article,
                                        affected_user: article.user)
      unlabeled_blocks.map do |code|
        answer = client.evaluate(state: { code: code.to_s.strip.first(MAX_BLOCK_CHARS) },
                                 questions: { language: language_question }).choice(:language)
        answer.confidence >= MIN_JEV_CONFIDENCE ? normalize_language(answer.choice) : "plaintext"
      rescue StandardError => e
        Rails.logger.error("Jev code block language detection failed for article #{article.id}: #{e}")
        "plaintext"
      end
    end

    def language_question
      @language_question ||= choice(
        "Which syntax-highlighting language is `code` written in?",
        self.class.language_criteria,
      )
    end

    # --- Gemini ---

    def extract_unlabeled_blocks
      article.body_markdown.to_enum(:scan, FENCED_CODE_BLOCK_REGEX).filter_map do
        match = Regexp.last_match
        next unless match[:info].to_s.strip.blank?

        match[:code]
      end
    end

    def build_prompt(unlabeled_blocks)
      blocks = unlabeled_blocks.each_with_index.map do |code, index|
        <<~BLOCK
          Block #{index + 1}:
          #{code.to_s.strip.first(MAX_BLOCK_CHARS)}
          #{code.to_s.length > MAX_BLOCK_CHARS ? "\n(Truncated)" : nil}
        BLOCK
      end.join("\n")

      <<~PROMPT
        You choose syntax-highlighting languages for markdown fenced code blocks.

        Choose exactly one language for each code block from this list of supported highlighting tags:
        #{SUPPORTED_LANGUAGE_TAGS.join(", ")}

        Rules:
        - Return ONLY a JSON array of strings in the same order as the blocks.
        - Each string must be one of the supported tags above.
        - If a block is ambiguous or plain text, use "plaintext".

        Example response:
        ["ruby", "javascript", "plaintext"]

        #{blocks}
      PROMPT
    end

    def parse_response(response, expected_count)
      parsed = JSON.parse(strip_code_fence(response.to_s))
      languages = parsed.is_a?(Array) ? parsed : parsed["languages"]
      languages = Array(languages).first(expected_count).map { |language| normalize_language(language) }
      languages.fill("plaintext", languages.length...expected_count)
    rescue JSON::ParserError, TypeError
      Array.new(expected_count, "plaintext")
    end

    def strip_code_fence(response)
      response.strip.gsub(/\A```(?:json)?\s*|\s*```\z/, "")
    end

    def normalize_language(language)
      lexer = Rouge::Lexer.find(language.to_s.strip.downcase)
      normalized_language = lexer&.tag

      if normalized_language.present? && SUPPORTED_LANGUAGE_TAGS.include?(normalized_language)
        normalized_language
      else
        "plaintext"
      end
    end

    def apply_languages(detected_languages)
      unlabeled_index = -1

      article.body_markdown.gsub(FENCED_CODE_BLOCK_REGEX) do
        match = Regexp.last_match
        next match[0] unless match[:info].to_s.strip.blank?

        unlabeled_index += 1
        language = detected_languages.fetch(unlabeled_index, "plaintext")

        "#{match[:leading]}#{match[:indent]}#{match[:fence]}#{language}\n#{match[:code]}\n" \
          "#{match[:indent]}#{match[:fence]}#{match[:closing_whitespace]}"
      end
    end
  end
end
