module Ai
  ##
  # Analyzes an article to determine its content moderation label.
  # This assesses articles based on quality, relevance, and spam indicators
  # to provide appropriate moderation labels for automated handling.
  #
  # When the :content_moderation function is set to Jev (see Ai::FunctionConfig), the single
  # "pick a label and a number" prompt is decomposed into independent TypeSafe questions
  # (safety, spam, quality, relevance, and three compellingness dimensions) asked in one
  # request. The label and score are then composed in code by #label_from_jev and
  # #compellingness_from_jev, using the same precedence as the prompt: safety, then spam,
  # then quality, then relevance.
  class ContentModerationLabeler
    include Ai::TypeSafe::Questions

    VERSION = "1.2".freeze
    FUNCTION_KEY = :content_moderation

    # Jev policy thresholds. "clear_and_obvious" labels require a high probability; "likely"
    # labels cover the uncertain band. Validate against moderator decisions before tuning.
    CLEAR = 0.85
    LIKELY = 0.6
    SUPPORTING = 0.5

    # Upper bounds on the quality Score position (0-4) for each quality tier.
    QUALITY_TIERS = [
      [0.75, :clear_low],
      [1.5, :likely_low],
      [2.5, :okay],
      [3.5, :very_good],
      [Float::INFINITY, :great],
    ].freeze

    # Status posts ("quickies") are tweet-length thoughts or commentary on a linked article.
    # Keep the low-quality floor identical so noise/filler is still filtered, while making
    # very_good and great attainable when the status post itself is genuinely insightful or
    # interesting.
    STATUS_QUALITY_TIERS = [
      [0.75, :clear_low],
      [1.5, :likely_low],
      [2.15, :okay],
      [3.15, :very_good],
      [Float::INFINITY, :great],
    ].freeze

    JEV_FALLBACK = { label: "no_moderation_label", compellingness_score: 0.0 }.freeze

    # Weights for composing compellingness from its dimensions. They sum to 1.
    COMPELLINGNESS_WEIGHTS = {
      originality: 0.35,
      personal_voice: 0.35,
      discussion_potential: 0.30
    }.freeze

    # @param article [Article] The article to be labeled.
    def initialize(article)
      @article = article
      @is_negative = @article.score.to_i.negative?
      @selection = Ai::FunctionConfig.selection_for(FUNCTION_KEY)
      return if @selection.jev?

      builtin_model = @is_negative ? Ai::Base::DEFAULT_LITE_MODEL : Ai::Base::DEFAULT_MODEL
      @ai_client = Ai::Base.new(model: @selection.gemini_model(builtin_model), wrapper: self,
                                affected_content: article, affected_user: article.user)
    end

    ##
    # Backward compatible wrapper for legacy evaluation.
    # @return [String] The moderation label for the article.
    def label
      evaluate[:label]
    end

    ##
    # Asks the AI to label the article and assess compellingness, returning both.
    # Retries up to 2 times on error before falling back to default.
    #
    # @return [Hash] Hash with :label and :compellingness_score.
    def evaluate
      return evaluate_via_jev if @selection.jev?

      attempt = 0
      max_retries = 2

      begin
        attempt += 1
        prompt = build_prompt
        # Pass json format request if the wrapper supports it, though explicit instructions might suffice.
        response = @ai_client.call(prompt, retry_count: attempt - 1, response_mime_type: "application/json")
        parse_response(response)
      rescue Ai::Base::ProhibitedContentError
        raise
      rescue StandardError => e
        Rails.logger.error("Content Moderation Labeling failed (attempt #{attempt}/#{max_retries + 1}): #{e}")

        if attempt <= max_retries
          sleep_duration = attempt * 2
          Rails.logger.info("Retrying content moderation labeling (attempt #{attempt + 1}/#{max_retries + 1}) after #{sleep_duration}s")
          sleep(sleep_duration) unless Rails.env.test?
          retry
        else
          Rails.logger.error("Content Moderation Labeling failed after #{max_retries + 1} attempts, falling back to default")
          # Fallback to a safe default after all retries exhausted
          { label: "no_moderation_label", compellingness_score: 0.0 }
        end
      end
    end

    private

    # --- Jev (TypeSafe System One) ---

    # The client already retries transient failures (429/529/5xx) with backoff.
    def evaluate_via_jev
      client = Ai::TypeSafe::Client.new(model: @selection.model, wrapper: self, affected_content: @article,
                                        affected_user: @article.user, **Ai::TypeSafe::Client::FAIL_FAST)
      result = client.evaluate(state: jev_state, questions: jev_questions)
      { label: label_from_jev(result), compellingness_score: compellingness_from_jev(result) }
    rescue StandardError => e
      Rails.logger.error("Content Moderation Labeling via Jev failed, falling back to default: #{e}")
      JEV_FALLBACK.dup
    end

    def jev_state
      user = @article.user
      limit = @is_negative ? 2000 : 5000
      format_description = if @article.status?
                             "status post (quickie): a short tweet-style update, thought, or commentary on a " \
                               "linked article/resource where title is the full post text"
                           else
                             "full post"
                           end
      article_state = {
        format: format_description,
        title: @article.title,
        tags: @article.cached_tag_list,
        body: @article.body_markdown.to_s.truncate(limit)
      }
      if @article.status?
        if linked_article
          article_state[:linked_article] = {
            title: linked_article.title,
            author: "@#{linked_article.cached_user_username}",
            tags: linked_article.cached_tag_list,
            excerpt: linked_article.body_markdown.to_s.truncate(400)
          }
        elsif embedded_urls.any?
          article_state[:linked_urls] = embedded_urls.first(3)
        end
      end

      state = {
        community: { description: community_description.presence || "No specific community description provided." },
        author: {
          member_since: user.created_at.strftime("%B %Y"),
          badge_achievements: user.badge_achievements_count,
          published_articles: user.articles.published.count,
          comments: user.comments.count,
          profile_summary: user.profile&.summary.presence || "No summary provided"
        },
        article: article_state
      }
      state[:community][:tag_moderation_instructions] = tag_instructions if tag_instructions.any?
      state
    end

    def jev_questions
      questions = {
        harmful: noul(
          "Does `article` involve human trafficking, doxing, exploitation, or calls for violence or harm " \
          "against people?",
          no: { includes: "Discussing security incidents, crime, or conflict in a factual or educational way." },
        ),
        inciting: noul(
          "Is `article` written with over-the-top aggression or rage designed to incite violence or extreme " \
          "hostility?",
          no: { includes: "Strong but civil opinions, criticism, or rants that do not target people with hostility." },
        ),
        promotional_spam: noul(
          {
            question: "Is `article` spam whose main purpose is to promote a product, service, or link?",
            rules: "Apply `community.tag_moderation_instructions` where they are relevant."
          },
          no: { includes: "An honest launch announcement or a tutorial that uses a product the author mentions." },
        ),
        malicious: noul(
          "Does `article` contain phishing, scams, or malicious links?",
        ),
        auto_generated: noul(
          "Does `article` read as generic, impersonal, mass-produced text with no real author perspective?",
        ),
        quality: quality_question,
        on_topic: noul(
          "Does the subject of `article` fit the purpose described in `community.description`?",
        ),
        originality: originality_question,
        personal_voice: personal_voice_question,
        discussion_potential: discussion_potential_question
      }
      if tag_instructions.any?
        questions[:violates_tag_rules] = noul(
          "Does `article` break a rule in `community.tag_moderation_instructions`?",
        )
      end
      questions
    end

    def quality_question
      if @article.status?
        score(
          {
            question: "How good is `article` as a short status post (tweet-length thought, observation, question, " \
                      "or commentary on a linked article) for this community?",
            focus: "Judge it on the scale of a developer tweet or curated link commentary, NOT a long-form article. " \
                   "In a status post, `article.title` is the full text of the post. Pointing out something " \
                   "interesting, insightful, or specific about `article.linked_article` or a linked resource " \
                   "counts as genuine quality, whereas bare noise or a commentary-free '[Boost]' does not.",
            rules: "Apply `community.tag_moderation_instructions` where they are relevant."
          },
          [
            "Low-effort or uninformative: meaningless noise (e.g. 'hi', 'test', 'up up'), a bare keyword, or " \
            "says nothing of substance.",
            "Weak: vague filler, generic self-promo, or a bare '[Boost]' / link drop with no real commentary or " \
            "point of view.",
            "Acceptable: a readable, on-topic casual update, simple question, or basic link share with brief context.",
            "Very good: would make an insightful or genuinely interesting developer tweet, shares a concrete tip " \
            "or question, or points out something specific and worthwhile about a linked article or project.",
            "Exceptional: a sharp, insightful, or memorable tweet-length observation or standout takeaway on a " \
            "linked article that community members will want to read and engage with.",
          ],
        )
      else
        score(
          {
            question: "How good is `article` as a contribution to this community?",
            status_posts: "If `article.format` is a status post, judge it as a short, casual update, " \
                          "not against long-form articles.",
            rules: "Apply `community.tag_moderation_instructions` where they are relevant."
          },
          [
            "Low-effort or uninformative: careless, unreadable, or says nothing of substance.",
            "Weak: some substance, but generic, thin, disorganized, or padded with filler.",
            "Acceptable: a readable, reasonable contribution with modest depth.",
            "Very good: clear, well-structured and informative, with real insight or experience.",
            "Exceptional: original and deep; the kind of post members share and cite.",
          ],
        )
      end
    end

    def originality_question
      if @article.status?
        score(
          "How original or interesting is the angle, takeaway, or observation in `article` " \
          "(as a short status post or commentary on a linked article)?",
          [
            "Empty filler, bare '[Boost]', or repeats a cliché with no angle of its own.",
            "A basic, familiar update or plain link summary.",
            "An interesting observation, concrete takeaway, or worthwhile angle on a topic or linked article.",
            "A sharp, distinctive insight, clever hook, or perspective that stands out in a feed.",
          ],
        )
      else
        score(
          "How original is the perspective or content of `article`?",
          [
            "Rehashes common material with nothing new.",
            "Mostly familiar material with a small new angle.",
            "A fresh angle, example, or finding.",
            "A distinctive idea or experience readers are unlikely to find elsewhere.",
          ],
        )
      end
    end

    def personal_voice_question
      if @article.status?
        score(
          "How much does `article` read like an authentic developer sharing a real thought, experience, " \
          "or take (rather than generic bot/marketing copy)?",
          [
            "Impersonal, robotic, or bare boilerplate.",
            "Plain and neutral with a hint of personal voice.",
            "Clearly a real person's voice, sharing their own take, project, or why a linked post is interesting.",
            "Vivid, authentic, and personable tweet-style voice.",
          ],
        )
      else
        score(
          "How much does `article` carry the author's own voice and lived experience?",
          [
            "Impersonal; could have been written by anyone.",
            "Occasional personal touches.",
            "Clearly the author's own voice, with personal experience.",
            "Vivid, personal, and emotionally resonant.",
          ],
        )
      end
    end

    def discussion_potential_question
      score(
        "How likely is `article` to spark discussion among community members?",
        [
          "Unlikely; nothing to respond to.",
          "Might draw a few polite replies.",
          "Raises points or questions members will want to weigh in on.",
          "Very likely to start a lively, substantive thread.",
        ],
      )
    end

    def label_from_jev(result)
      safety_label(result) || spam_label(result) || quality_label(result)
    end

    def safety_label(result)
      harmful = result.noul(:harmful)
      inciting = result.noul(:inciting)
      return "clear_and_obvious_harmful" if harmful >= CLEAR
      return "clear_and_obvious_inciting" if inciting >= CLEAR
      return "likely_harmful" if harmful >= LIKELY

      "likely_inciting" if inciting >= LIKELY
    end

    def spam_label(result)
      promotional = result.noul(:promotional_spam)
      spam = [result.noul(:malicious), promotional].max
      # Generic, machine-like text is a spam signal only when it is also promotional.
      spam = CLEAR if result.noul(:auto_generated) >= CLEAR && promotional >= SUPPORTING
      return "clear_and_obvious_spam" if spam >= CLEAR

      "likely_spam" if spam >= LIKELY
    end

    def quality_label(result)
      tier = quality_tier(result.score(:quality).score)
      tier = :likely_low if tag_rule_violation?(result) && %i[okay very_good great].include?(tier)
      tier = :okay if @is_negative && %i[very_good great].include?(tier)

      return "clear_and_obvious_low_quality" if tier == :clear_low
      return "likely_low_quality" if tier == :likely_low

      relevance_label(tier, on_topic: result.noul(:on_topic) >= SUPPORTING)
    end

    def quality_tier(position)
      tiers = @article.status? ? STATUS_QUALITY_TIERS : QUALITY_TIERS
      tiers.detect { |upper_bound, _tier| position < upper_bound }.last
    end

    def tag_rule_violation?(result)
      result.key?(:violates_tag_rules) && result.noul(:violates_tag_rules) >= CLEAR
    end

    def relevance_label(tier, on_topic:)
      case tier
      when :okay then on_topic ? "okay_and_on_topic" : "ok_but_offtopic_for_subforem"
      when :very_good then on_topic ? "very_good_and_on_topic" : "very_good_but_offtopic_for_subforem"
      when :great then on_topic ? "great_and_on_topic" : "great_but_off_topic_for_subforem"
      end
    end

    # Weighted blend of normalized dimension Scores, rounded for storage. Used for ranking
    # in feeds, not as an exact magnitude.
    def compellingness_from_jev(result)
      COMPELLINGNESS_WEIGHTS.sum { |dimension, weight| weight * result.score(dimension).normalized }
        .clamp(0.0, 1.0).round(3)
    end

    def community_description
      subforem_id = @article.subforem_id || RequestStore.store[:default_subforem_id] || Subforem.cached_default_id
      if subforem_id
        Settings::RateLimit.internal_content_description_spec(subforem_id: subforem_id).presence ||
          Settings::Community.community_description(subforem_id: subforem_id).presence ||
          Settings::RateLimit.internal_content_description_spec.presence ||
          Settings::Community.community_description
      else
        Settings::RateLimit.internal_content_description_spec.presence ||
          Settings::Community.community_description
      end
    end

    def tag_instructions
      @tag_instructions ||= @article.tags.where.not(moderation_instructions: [nil, ""])
        .pluck(:name, :moderation_instructions)
        .map { |name, instructions| { tag: name, instructions: instructions } }
    end

    def embedded_urls
      @embedded_urls ||= begin
        urls = []
        urls << @article.body_url if @article.respond_to?(:body_url) && @article.body_url.present?
        if @article.body_markdown.present?
          @article.body_markdown.scan(%r{\{%\s*embed\s+(https?://[^\s%]+)}i) { |match| urls << match.first }
        end
        urls.concat(@article.extract_urls_from_title) if @article.respond_to?(:extract_urls_from_title)
        urls.filter_map { |url| url.to_s.strip.sub(/[.,;:!?)]+$/, "").presence }.uniq
      end
    end

    def linked_article
      return @linked_article if defined?(@linked_article)

      @linked_article = if @article.status?
                          embedded_urls.lazy.filter_map do |url|
                            path = URI.parse(url).path.to_s.downcase.chomp("/")
                            next if path.blank? || path.count("/") < 2

                            Article.published
                              .where.not(id: @article.id)
                              .select(:id, :title, :cached_user_username, :cached_tag_list, :body_markdown)
                              .find_by(path: path)
                          rescue URI::Error
                            nil
                          end.first
                        end
    end

    # --- Gemini ---

    ##
    # Builds a detailed prompt for the AI to assess article content.
    # @return [String] The prompt to be sent to the Gemini API.
    def build_prompt
      # Gather user context
      user_context = build_user_context

      # Gather article context
      article_context = build_article_context

      # Gather custom tag moderation instructions
      tag_instructions_context = build_tag_instructions_context

      quickie_context = if @article.status?
                          <<~QUICKIE

                            **Important Context — Status Post ("Quickie") Calibration:**
                            Note: This article is a "status" post (a short, tweet-length update, thought, question, or commentary on a linked article/resource). In status posts, the `Title` field contains the entire text of the post, and `Body` is either empty or contains an `{% embed ... %}` link.
                            Do NOT judge a status post against long-form blog post criteria (do not require multiple paragraphs, section headers, or long-form depth). Instead, calibrate quality labels and `compellingness_score` against what makes a genuinely good developer tweet or link commentary:
                            - **Assign `great_and_on_topic` (and `compellingness_score` 0.80–1.0)** when the status post is a sharp, insightful, clever, or memorable developer thought/observation, a great discussion prompt, or a compelling takeaway that highlights something genuinely interesting or surprising about a linked article or project.
                            - **Assign `very_good_and_on_topic` (and `compellingness_score` 0.65–0.85)** when the status post would make an insightful or genuinely interesting developer tweet/update, asks a worthwhile community question, shares a concrete tip, or points out something specific, useful, or interesting about a linked article or resource (rather than just dropping a bare link).
                            - **Assign `okay_and_on_topic` (and `compellingness_score` 0.35–0.60)** only when the status post is a plain, unremarkable on-topic update, a generic announcement with no real insight/hook, or a bare `[Boost]` of an on-topic post with no added commentary.
                            - **Maintain strict quality & spam standards (`likely_low_quality`, `clear_and_obvious_low_quality`, `likely_spam`, `clear_and_obvious_spam`)**: Do NOT reward low-effort noise (e.g., bare greetings like "hi" or "first time here", test posts, "up up", single keywords, engagement bait with no substance, or spam/off-topic promotional links). Real quality and genuine insight or interest are still strictly required.
                          QUICKIE
                        else
                          ""
                        end

      <<~PROMPT
        Analyze the following article and assign it a content moderation label based on quality, relevance, and community standards.

        **Community Context:**
        #{community_description.presence || 'No specific community description provided.'}
        #{tag_instructions_context}

        **User Context:**
        #{user_context}

        **Article Content:**
        #{article_context}#{quickie_context}

        **Assessment Criteria:**

        1. **Safety First**: Is the content harmful, exploitative, or inciting violence/hostility?
        2. **Content Quality**: Is the content well-written, informative, and valuable?
        3. **Community Relevance**: Does the content align with the community's purpose and interests?
        4. **Authenticity**: Does the content appear to be written by a real person with genuine insights?
        5. **Spam Indicators**: Are there signs of promotional content, low-effort posts, or automated generation?
        6. **Community Building**: Does the content foster discussion and community engagement?
        7. **Compellingness**: Evaluate factors such as originality, emotional resonance, clarity, personal touch, depth, groundedness, and the potential to spark discussion.

        **Label Categories:**

        **Safety Labels (Highest Priority):**
        - `clear_and_obvious_harmful`: Content involving human trafficking, doxing, calls for violence, or other clearly exploitative/harmful content
        - `likely_harmful`: Content that appears to involve harmful activities but not definitively so
        - `clear_and_obvious_inciting`: Over-the-top aggression, direct rage, or content clearly designed to incite violence or extreme hostility
        - `likely_inciting`: Content that appears to be inciting but not definitively so

        **Spam Labels:**
        - `clear_and_obvious_spam`: Obvious promotional content, automated posts, or malicious content
        - `likely_spam`: Content with strong spam indicators but not definitively spam

        **Quality Labels:**
        - `clear_and_obvious_low_quality`: Poorly written, uninformative, or clearly low-effort content
        - `likely_low_quality`: Content that appears low quality but not definitively so

        **Relevance Labels:**
        - `ok_but_offtopic_for_subforem`: Decent content but not relevant to this community
        - `okay_and_on_topic`: Acceptable content that fits the community
        #{ @is_negative ? "" : <<~EXTRA_LABELS
        - `very_good_but_offtopic_for_subforem`: High-quality content but not relevant to this community
        - `very_good_and_on_topic`: High-quality content that fits the community well
        - `great_and_on_topic`: Exceptional content that perfectly fits the community
        - `great_but_off_topic_for_subforem`: Exceptional content but not relevant to this community
        EXTRA_LABELS
        }

        **Compellingness Score Requirements:**
        In addition to the moderation label, assess the "compellingness" of the article on a scale from 0.0 to 1.0. 
        - 0.0 indicates content that is uninteresting, generic, or spam-like.
        - 1.0 indicates content that is exceptionally engaging, unique, personable, insightful, and thought-provoking.

        **Guidelines for Labeling:**

        **Safety Indicators (Check First):**
        - Content involving human trafficking, exploitation, or illegal activities
        - Doxing (sharing private personal information without consent)
        - Direct calls for violence or harm against individuals/groups
        - Over-the-top aggression, rage, or hostility that could incite violence
        - Content designed to provoke extreme emotional responses or conflict

        **Spam Indicators:**
        - Excessive promotional language or links
        - Generic, impersonal content that could be AI-generated
        - Content that doesn't engage with the community
        - Suspicious patterns or automated behavior

        **Quality Indicators:**
        - Well-structured, thoughtful content
        - Personal experiences and genuine insights
        - Proper formatting and readability
        - Evidence of research or expertise

        **Relevance Indicators:**
        - Content that addresses community interests
        - Topics that align with the community's purpose
        - Content that would be valuable to community members

        Respond ONLY with a raw JSON block containing exactly two fields: "moderation_label" (string) and "compellingness_score" (float). Do not wrap the JSON in markdown code blocks.
        Example: {"moderation_label": "okay_and_on_topic", "compellingness_score": 0.85}
      PROMPT
    end

    ##
    # Builds context about the user who wrote the article.
    # @return [String] User context information.
    def build_user_context
      user = @article.user
      <<~USER_CONTEXT
        Author: #{user.name} (@#{user.username})
        Member since: #{user.created_at.strftime('%B %Y')}
        Badge achievements: #{user.badge_achievements_count}
        Articles published: #{user.articles.published.count}
        Comments made: #{user.comments.count}
        Profile summary: #{user.profile&.summary || 'No summary provided'}
      USER_CONTEXT
    end

    ##
    # Builds context about the article content.
    # @return [String] Article context information.
    def build_article_context
      limit = @is_negative ? 2000 : 5000
      word_count = if @article.status?
                     "#{@article.title} #{@article.body_markdown}".split.size
                   else
                     @article.body_markdown.split.size
                   end
      linked_context = if @article.status? && linked_article
                         <<~LINKED
                           Linked Article: "#{linked_article.title}" by @#{linked_article.cached_user_username} (Tags: #{linked_article.cached_tag_list})
                           Linked Article Excerpt: #{linked_article.body_markdown.to_s.truncate(400)}
                         LINKED
                       elsif @article.status? && embedded_urls.any?
                         "Linked URL(s): #{embedded_urls.first(3).join(', ')}\n"
                       else
                         ""
                       end
      <<~ARTICLE_CONTEXT
        Title: #{@article.title}
        Tags: #{@article.cached_tag_list}
        Body: #{@article.body_markdown.truncate(limit)} #{'(Truncated)' if @article.body_markdown.length > limit}
        #{linked_context}Published: #{@article.published_at&.strftime('%B %d, %Y') || 'Not published'}
        Reading time: #{@article.reading_time} minutes
        Word count: #{word_count} words
      ARTICLE_CONTEXT
    end

    def build_tag_instructions_context
      tag_instructions = @article.tags.where.not(moderation_instructions: [nil, ""]).pluck(:name, :moderation_instructions)
      return "" if tag_instructions.empty?

      instructions_list = tag_instructions.map do |name, inst|
        "- ##{name}: #{inst}"
      end.join("\n")

      <<~CONTEXT

        **Custom Tag Moderation Instructions:**
        The article is tagged with the following tags, which have custom moderation instructions that you must follow during your assessment:
        #{instructions_list}
      CONTEXT
    end

    ##
    # Parses the AI's response to extract the label and score from JSON.
    # @param response [String] The text response from the AI.
    # @return [Hash] The Extracted Hash.
    def parse_response(response)
      fallback = { label: "no_moderation_label", compellingness_score: 0.0 }
      return fallback unless response
      
      valid_labels = %w[
        no_moderation_label clear_and_obvious_harmful likely_harmful
        clear_and_obvious_inciting likely_inciting clear_and_obvious_spam
        likely_spam clear_and_obvious_low_quality likely_low_quality
        ok_but_offtopic_for_subforem okay_and_on_topic very_good_but_offtopic_for_subforem
        very_good_and_on_topic great_and_on_topic great_but_off_topic_for_subforem
      ]

      begin
        # Clean potential markdown wrapping (e.g. ```json ... ```)
        cleaned_response = response.strip.gsub(/\A```json\s*/, '').gsub(/\s*```\Z/, '').strip
        data = JSON.parse(cleaned_response)

        label = data["moderation_label"].to_s.strip.downcase.gsub(/[^a-z_]/, "")
        score = data["compellingness_score"].to_f

        final_label = valid_labels.include?(label) ? label : "no_moderation_label"
        final_score = score.clamp(0.0, 1.0)
        
        { label: final_label, compellingness_score: final_score }
      rescue JSON::ParserError => e
        Rails.logger.error("Content Moderation JSON Parsing Error: #{e}. Response was: #{response}")
        
        # Fallback to legacy string parsing / scanning
        final_label = valid_labels.sort_by(&:length).reverse.find { |l| response.downcase.include?(l) } || "no_moderation_label"
        
        { label: final_label, compellingness_score: 0.0 }
      end
    end
  end
end
