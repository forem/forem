module Ai
  class OrgPageGenerator
    VERSION = "2.0"
    MAX_RETRIES = 3
    ORG_WIZARD_MODEL = ENV.fetch("GEMINI_WIZARD_MODEL", "gemini-3.1-pro").freeze
    PLANNER_MODEL = ENV.fetch("GEMINI_PLANNER_MODEL", "gemini-3.1-flash-lite-preview").freeze

    VALID_SECTION_TYPES = %w[hero features social_proof community comments org_posts team youtube slides lead_form cta].freeze

    def initialize(organization:, org_data:, dev_posts: [])
      @organization = organization
      @org_data = org_data
      @dev_posts = dev_posts
      @ai_client = Ai::Base.new(model: ORG_WIZARD_MODEL, wrapper: self, affected_content: organization)
      @planner_client = Ai::Base.new(model: PLANNER_MODEL, wrapper: self, affected_content: organization)

      # Memoize frequently-queried org attributes to avoid repeated DB hits
      @team_count = @organization.users.count
      @has_org_posts = @organization.articles.published.any?
      @active_lead_form = @organization.lead_forms.active.first
      @has_lead_form = @active_lead_form.present?
      @youtube_urls = extract_youtube_urls
    end

    def generate
      plan = plan_sections
      Rails.logger.info("OrgPageGenerator plan: #{plan.map { |s| s['type'] }.join(' → ')}")

      sections = plan.filter_map { |section_plan| generate_section(section_plan) }

      if sections.length < 2
        Rails.logger.warn("OrgPageGenerator: only #{sections.length} sections generated, falling back to single-shot")
        return generate_single_shot
      end

      markdown = sections.join("\n\n")
      markdown = qa_review(markdown)
      markdown = self_review(markdown)
      markdown, html = validate_and_fix(markdown)
      { markdown: markdown, html: html }
    rescue StandardError => e
      Rails.logger.warn("OrgPageGenerator pipeline failed (#{e.message}), falling back to single-shot")
      generate_single_shot
    end

    def generate_single_shot
      markdown = generate_with_retry(build_generate_prompt)
      markdown = qa_review(markdown)
      markdown = self_review(markdown)
      markdown, html = validate_and_fix(markdown)
      { markdown: markdown, html: html }
    end

    def iterate(current_markdown:, instruction:)
      prompt = build_iterate_prompt(current_markdown, instruction)
      markdown = generate_with_retry(prompt)
      markdown = qa_review(markdown)
      markdown = self_review(markdown)
      markdown, html = validate_and_fix(markdown)
      { markdown: markdown, html: html }
    end

    private

    def generate_with_retry(prompt)
      retries = 0
      last_error = nil

      while retries < MAX_RETRIES
        begin
          response = @ai_client.call(prompt)
          markdown = clean_response(response)
          raise StandardError, "AI returned blank response" if markdown.blank?

          render_markdown(markdown) # validate
          return markdown
        rescue ContentRenderer::ContentParsingError => e
          retries += 1
          last_error = e.message
          Rails.logger.warn("OrgPageGenerator attempt #{retries} validation failed: #{e.message}")
          prompt = build_fix_prompt(markdown, e.message) if retries < MAX_RETRIES
        rescue StandardError => e
          retries += 1
          last_error = e.message
          Rails.logger.warn("OrgPageGenerator attempt #{retries} failed: #{e.message}")
          sleep(1) if retries < MAX_RETRIES
        end
      end

      Rails.logger.error("OrgPageGenerator failed after #{MAX_RETRIES} attempts: #{last_error}")
      raise "Failed to generate valid page after #{MAX_RETRIES} attempts"
    end

    # --- Validate & Fix Loop ---
    # Renders markdown to HTML, checks for liquid errors embedded in the output,
    # and sends broken markdown back to AI for fixing. Retries up to MAX_RETRIES.

    LIQUID_ERROR_PATTERNS = [
      /Liquid syntax error/,
      /Liquid error/,
      /Tag '[^']+' was not properly terminated/,
      /tag was never closed/,
    ].freeze

    NETWORK_ERROR_PATTERNS = [
      /Failed to open TCP connection/,
      /getaddrinfo/,
      /Connection refused/,
      /Net::OpenTimeout/,
      /SocketError/,
    ].freeze

    def validate_and_fix(markdown)
      retries = 0

      loop do
        begin
          html = render_markdown(markdown)
        rescue StandardError => e
          # Network errors during rendering (embed tags fetching URLs) are not fixable by AI
          if NETWORK_ERROR_PATTERNS.any? { |p| e.message.match?(p) }
            Rails.logger.warn("OrgPageGenerator network error during render, skipping validation: #{e.message}")
            return [markdown, ""]
          end
          raise
        end

        error = detect_render_errors(html)

        if error.nil?
          return [markdown, html]
        end

        retries += 1
        if retries > MAX_RETRIES
          Rails.logger.error("OrgPageGenerator validate_and_fix failed after #{MAX_RETRIES} attempts: #{error}")
          raise "Page contains rendering errors after #{MAX_RETRIES} fix attempts: #{error}"
        end

        Rails.logger.warn("OrgPageGenerator render error (attempt #{retries}): #{error}")
        response = @ai_client.call(build_fix_prompt(markdown, error))
        markdown = clean_response(response)
        markdown = qa_review(markdown)
      end
    end

    def detect_render_errors(html)
      LIQUID_ERROR_PATTERNS.each do |pattern|
        match = html.match(pattern)
        return match[0] if match
      end

      # Check for broken liquid tags rendered as plain text (unclosed tags)
      if html.match?(/\{%[^}]*$/) || html.match?(/\{%\s*end\w+\s*%\}.*\{%\s*end\w+\s*%\}/m)
        return "Malformed liquid tag detected in output"
      end

      nil
    end

    # --- Self-Review: AI evaluates its own rendered output ---
    # The AI sees the rendered HTML and checks for quality issues.
    # Protected sections (deterministic liquid tags) are extracted before the fix
    # and restored after, so the AI can't corrupt slugs/ids.

    PROTECTED_TAG_PATTERN = /\{%\s*(?:org_posts|org_team|org_lead_form|comment|youtube|link)\s[^%]*%\}/

    def self_review(markdown)
      html = render_markdown(markdown)
      review = @ai_client.call(build_self_review_prompt(markdown, html), json_mode: true)
      parsed = JSON.parse(review)

      if parsed["pass"] == true
        Rails.logger.info("OrgPageGenerator self-review: PASS (score: #{parsed['score']})")
        return markdown
      end

      issues = parsed["issues"] || []
      Rails.logger.info("OrgPageGenerator self-review: FAIL (score: #{parsed['score']}, issues: #{issues.length}: #{issues.join('; ')})")

      # Only fix if there are actionable issues the AI can actually address
      fixable = issues.reject { |i| i.match?(/missing.*section|no.*team|no.*org_posts/i) }
      if fixable.empty?
        Rails.logger.info("OrgPageGenerator self-review: no fixable issues, keeping original")
        return markdown
      end

      # Protect deterministic tags from being rewritten — use realistic-looking placeholders
      protected_tags = {}
      protected_markdown = markdown.gsub(PROTECTED_TAG_PATTERN) do |match|
        key = "<!-- KEEP_BLOCK_#{protected_tags.length} -->"
        protected_tags[key] = match
        key
      end

      issues_text = fixable.map { |i| "- #{i}" }.join("\n")
      fix_response = @ai_client.call(build_self_review_fix_prompt(protected_markdown, issues_text),
                                     system_instruction: section_system_instruction)
      fixed = clean_response(fix_response)

      if fixed.blank?
        Rails.logger.warn("OrgPageGenerator self-review fix returned blank, keeping original")
        return markdown
      end

      # Restore protected tags — check which ones the AI kept
      dropped = []
      protected_tags.each do |key, tag|
        if fixed.include?(key)
          fixed = fixed.gsub(key, tag)
        else
          Rails.logger.warn("OrgPageGenerator self-review dropped protected tag: #{tag.truncate(60)}")
          dropped << tag
        end
      end

      # Re-inject any dropped tags before the last ## heading (usually CTA)
      if dropped.any?
        inject_point = fixed.rindex(/^##/m) || fixed.length
        fixed = fixed.insert(inject_point, dropped.join("\n\n") + "\n\n")
      end

      qa_review(fixed)
    rescue StandardError => e
      Rails.logger.warn("OrgPageGenerator self-review failed, using original: #{e.message}")
      markdown
    end

    def build_self_review_prompt(markdown, html)
      <<~PROMPT
        You are reviewing an organization page for "#{@organization.name}" on DEV.to.

        Here is the MARKDOWN source:
        #{markdown}

        Here is the RENDERED HTML output (truncated):
        #{html.truncate(8000)}

        Check ONLY for these specific problems:
        1. Placeholders left in (e.g. [Add X here], [TODO], placeholder text)
        2. Sections with headings but no meaningful content below them
        3. HTML entities showing as text (e.g. &amp; instead of &)
        4. The same text or section repeated multiple times
        5. Generic filler that doesn't mention "#{@organization.name}" specifically
        6. Hallucinated quotes or statistics not from the source data

        DO NOT flag these as issues:
        - Liquid tags like {% org_posts %}, {% org_team %}, {% youtube %}, {% comment %}, {% link %} — these are correct even if the HTML shows them as embeds
        - Sections being in a particular order — ordering is intentional
        - Lack of images or visual elements

        Respond with JSON:
        {
          "pass": true/false,
          "score": 1-10,
          "issues": ["specific issue description"]
        }

        Set "pass" to true if score >= 6 and no placeholders or hallucinated content found.
      PROMPT
    end

    def build_self_review_fix_prompt(markdown, issues_text)
      <<~PROMPT
        Fix ONLY these specific issues in the DEV.to organization page for "#{@organization.name}":

        ISSUES TO FIX:
        #{issues_text}

        CURRENT MARKDOWN:
        #{markdown}

        CRITICAL RULES:
        - ONLY fix the specific issues listed above
        - Do NOT rewrite, reorder, or restructure the page
        - Do NOT remove or change any HTML comments like <!-- KEEP_BLOCK_0 --> — these are required embed placeholders
        - Do NOT change {% org_posts %}, {% org_team %}, {% youtube %}, {% comment %}, {% link %} tags
        - Remove placeholders — replace with real content or delete the line
        - Fix HTML entities (& not &amp;)
        - Remove duplicate sections (keep the first occurrence)
        - Output the COMPLETE page markdown, no explanations, no code blocks
      PROMPT
    end

    # --- Pipeline: Plan → Generate per-section → Assemble ---

    def plan_sections
      response = @planner_client.call(build_plan_prompt, json_mode: true)
      parse_plan(response)
    end

    def parse_plan(response)
      json_str = response.to_s.strip
      # Handle both raw array and wrapped {"sections": [...]} responses
      parsed = JSON.parse(json_str)
      sections = parsed.is_a?(Array) ? parsed : (parsed["sections"] || parsed.values.first || [])
      sections = sections.select { |s| VALID_SECTION_TYPES.include?(s["type"]) }
      ensure_required_sections(sections)
    rescue JSON::ParserError => e
      Rails.logger.warn("OrgPageGenerator plan parsing failed: #{e.message}, using default plan")
      default_plan
    end

    def ensure_required_sections(sections)
      types = sections.map { |s| s["type"] }
      has_youtube = @youtube_urls.any? || @org_data[:youtube_urls].present?

      # Inject required sections before cta if missing
      cta_idx = types.index("cta") || sections.length
      unless types.include?("org_posts")
        sections.insert(cta_idx, { "type" => "org_posts" })
        types = sections.map { |s| s["type"] }
        cta_idx += 1
      end
      unless types.include?("team")
        sections.insert(cta_idx, { "type" => "team" })
        types = sections.map { |s| s["type"] }
        cta_idx += 1
      end
      if has_youtube && !types.include?("youtube")
        sections.insert(cta_idx, { "type" => "youtube" })
      end

      sections
    end

    def default_plan
      # Minimal fallback if planner fails — just lists available sections in a safe order
      available = [{ "type" => "hero" }]
      available << { "type" => "features" } if @org_data[:features].present?
      available << { "type" => "social_proof" } if @org_data[:testimonials].present?
      available << { "type" => "youtube" } if @youtube_urls.any? || @org_data[:youtube_urls].present?
      available << { "type" => "community" } if @dev_posts.present?
      available << { "type" => "slides" } if @org_data[:content_images].present?
      available << { "type" => "team" } if @team_count > 1
      available << { "type" => "comments" } if @org_data[:dev_comments].present?
      available << { "type" => "org_posts" } if @has_org_posts
      available << { "type" => "lead_form" } if @has_lead_form
      available << { "type" => "cta" }
      available
    end

    def generate_section(section_plan)
      section_type = section_plan["type"]

      # Deterministic sections — no AI call needed, just exact tags
      deterministic = build_deterministic_section(section_type)
      return deterministic if deterministic

      # AI-generated sections
      prompt = build_section_prompt(section_type)
      return nil if prompt.nil?

      response = @ai_client.call(prompt, system_instruction: section_system_instruction)
      markdown = clean_response(response)
      return nil if markdown.blank?

      markdown
    rescue StandardError => e
      Rails.logger.warn("OrgPageGenerator section '#{section_type}' failed: #{e.message}")
      nil
    end

    def section_system_instruction
      @section_system_instruction ||= <<~INSTRUCTION
        You are a page designer for DEV.to organization pages. You output ONLY raw markdown with liquid tags — never explanations, never code blocks.

        ABSOLUTE RULES:
        - ONLY use these liquid tags: features/feature, quote, offer, org_posts, org_team, org_lead_form, slides/slide, youtube, link, comment, embed
        - Tags like {% forem %}, {% banner %}, {% hero %}, {% section %}, {% card %}, {% grid %}, {% button %} do NOT exist
        - Use {% offer %} for external links, NEVER markdown links [text](url)
        - Use {% youtube VIDEO_URL %} for YouTube videos, NEVER {% embed %} for YouTube
        - NEVER leave placeholders like [Add X here], [TODO], [Insert Y] — only final publishable content
        - NEVER use HTML entities in markdown (& not &amp;, < not &lt;)
        - NEVER fabricate testimonials, statistics, or quotes

        OFFER TAG QUALITY:
        - The button text MUST be an action verb phrase: "Get Started", "View the Docs", "Try the API", "Explore on GitHub"
        - The description MUST be a compelling sentence explaining what the user gets — NEVER just a domain name or repeat of the button
        - NEVER use a bare domain like "Github.com" or "Twilio.com" as button text or description
        - Limit to 2-3 offer tags per page. Every link does NOT need an offer — only the primary CTAs.
      INSTRUCTION
    end

    def build_deterministic_section(section_type)
      case section_type
      when "community"
        return nil if @dev_posts.blank?

        posts = @dev_posts.map { |p| "{% link #{p[:path].to_s.delete_prefix('/')} %}" }.join("\n\n")
        "## From the Community\n\n#{posts}"
      when "org_posts"
        return nil unless @has_org_posts

        "## Our Latest on DEV\n\n{% org_posts #{@organization.slug} limit=5 sort=reactions %}"
      when "team"
        return nil unless @team_count > 1

        "## Meet the Team\n\n{% org_team #{@organization.slug} limit=10 %}"
      when "comments"
        comments = @org_data[:dev_comments]
        return nil if comments.blank?

        embeds = comments.first(3).map { |c| "{% comment #{c['id_code'] || c[:id_code]} %}" }.join("\n\n")
        "## What Developers Are Saying\n\n#{embeds}"
      when "youtube"
        all_youtube = (@youtube_urls + (@org_data[:youtube_urls] || []))
          .select { |u| u.match?(%r{youtube\.com/watch\?v=|youtu\.be/[\w-]}) }
          .uniq.first(3)
        return nil if all_youtube.empty?

        if all_youtube.length == 1
          "## Watch\n\n{% youtube #{all_youtube.first} %}"
        else
          slides = all_youtube.map { |u| "{% slide video=\"#{u}\" %}" }.join("\n")
          "## Watch\n\n{% slides %}\n#{slides}\n{% endslides %}"
        end
      when "slides"
        images = @org_data[:content_images]
        return nil if images.blank?

        slides = images.map do |img|
          url = img["url"] || img[:url]
          alt = img["alt"] || img[:alt] || ""
          "{% slide image=\"#{url}\" alt=\"#{alt}\" %}"
        end.join("\n")
        "## Gallery\n\n{% slides %}\n#{slides}\n{% endslides %}"
      when "lead_form"
        lead_form_id = @active_lead_form&.id
        return nil unless lead_form_id

        "## Stay Connected\n\n{% org_lead_form #{lead_form_id} %}"
      end
    end

    def build_plan_prompt
      page_type = @org_data[:page_type] || "developer"
      has_features = @org_data[:features].present?
      has_dev_posts = @dev_posts.present?
      has_team = @team_count > 1
      has_lead_form = @has_lead_form
      has_org_posts = @has_org_posts
      has_youtube = @youtube_urls.any? || @org_data[:youtube_urls].present?
      has_testimonials = @org_data[:testimonials].present?
      has_comments = @org_data[:dev_comments].present?
      has_images = @org_data[:content_images].present?

      <<~PROMPT
        You are planning the section layout for a #{page_type} organization page on DEV.to for "#{@organization.name}".

        #{page_type_guidance(page_type)}

        AVAILABLE CONTENT:
        - Tagline: #{@org_data[:title].present? ? "YES (\"#{@org_data[:title]}\")" : 'NO'}
        - Description: #{@org_data[:description].present? ? 'YES' : 'NO'}
        - Features extracted: #{has_features ? "YES (#{@org_data[:features].length} features)" : 'NO'}
        - Links: #{@org_data[:links]&.map { |l| l[:label] }&.join(', ') || 'NONE'}
        - Real testimonials extracted: #{has_testimonials ? "YES (#{@org_data[:testimonials].length} quotes)" : 'NO'}
        - DEV comments mentioning org: #{has_comments ? "YES (#{@org_data[:dev_comments].length} comments)" : 'NO'}
        - DEV posts to embed: #{has_dev_posts ? "YES (#{@dev_posts.length} posts)" : 'NO'}
        - Team members on DEV: #{has_team ? "YES (#{@team_count} members)" : 'NO'}
        - Organization articles on DEV: #{has_org_posts ? 'YES' : 'NO'}
        - Lead capture form: #{has_lead_form ? 'YES' : 'NO'}
        - YouTube videos: #{has_youtube ? 'YES' : 'NO'}
        - Content images for gallery: #{has_images ? "YES (#{@org_data[:content_images].length} images)" : 'NO'}

        SECTION TYPES:

        REQUIRED (always include):
        - "hero": Opening headline, subheadline, and primary CTA. Must be first.
        - "org_posts": Organization's published articles feed. ALWAYS include — this is a DEV.to page, the org's articles are core content.
        - "team": Team member showcase. ALWAYS include — shows the people behind the org.
        #{has_youtube ? '- "youtube": YouTube video embeds. ALWAYS include when videos are available — video content is high-value.' : ''}
        - "cta": Final call-to-action. Must be last.

        OPTIONAL (include if content exists):
        - "features": Feature grid (if features data exists or can be inferred).
        - "social_proof": Real testimonial quotes (ONLY if testimonials is YES above).
        - "community": Embedded DEV posts written about the org (if DEV posts available).
        - "comments": DEV community comments mentioning the org (if comments available).
        #{has_youtube ? '' : '- "youtube": YouTube video embeds (if YouTube URLs exist).'}
        - "slides": Image gallery carousel (if content images available).
        - "lead_form": Lead capture form (if lead form exists).

        YOUR JOB: Decide the best ordering for this specific page type and organization. Think about narrative flow — what order tells the best story to the visitor?

        CONSTRAINTS:
        - "hero" must be first, "cta" must be last
        - "org_posts" and "team" must be included somewhere in between
        - Do NOT include optional sections for content that doesn't exist (marked NO above)
        - Avoid placing "community", "comments", and "org_posts" adjacent — interleave with other section types
        - 5-8 sections total
        - Return ONLY a JSON array, no other text
      PROMPT
    end

    def build_section_prompt(section_type)
      case section_type
      when "hero" then build_hero_section_prompt
      when "features" then build_features_section_prompt
      when "social_proof" then build_social_proof_section_prompt
      when "community" then build_community_section_prompt
      when "org_posts" then build_org_posts_section_prompt
      when "team" then build_team_section_prompt
      when "youtube" then build_youtube_section_prompt
      when "lead_form" then build_lead_form_section_prompt
      when "cta" then build_cta_section_prompt
      end
    end

    def build_hero_section_prompt
      primary_link = @org_data[:links]&.first
      page_type = @org_data[:page_type] || "developer"

      <<~PROMPT
        Write a hero section for "#{@organization.name}"'s DEV.to organization page.

        #{page_type_guidance(page_type)}

        Organization: #{@organization.name}
        Tagline: #{@org_data[:title]}
        Description: #{@org_data[:description]}
        Primary link: #{primary_link ? "#{primary_link[:label]}: #{primary_link[:url]}" : 'none'}

        AVAILABLE TAGS:
        - ## Heading for the headline
        - Regular markdown text for subheadline
        - {% offer link="URL" button="Button Text" %}Description{% endoffer %} for CTA

        GOOD offer example: {% offer link="https://twilio.com/docs" button="Explore the Docs" %}Start building with Twilio's APIs in minutes{% endoffer %}
        BAD offer example: {% offer link="https://github.com/twilio" button="Github.com" %}Github.com{% endoffer %}
        The button text must be an ACTION VERB phrase, and the description must be a compelling sentence — never just a domain name.

        RULES:
        - Headline under 10 words, benefit-driven or problem-solving
        - 1-2 sentence subheadline explaining what the org does and for whom
        - Include ONE {% offer %} CTA if a link is available
        - The offer button must use action verbs (e.g. "Get Started", "View the Docs", "Try It Free")
        - The offer description must be a compelling sentence, NOT a repeat of the button text or URL
        - NEVER use markdown links [text](url) — use {% offer %} instead
        - NEVER leave placeholders — only output final content
        - Output ONLY the section markdown, no explanations, no code blocks
      PROMPT
    end

    def build_features_section_prompt
      features = @org_data[:features] || []
      page_type = @org_data[:page_type] || "developer"

      <<~PROMPT
        Write a features section for "#{@organization.name}"'s DEV.to organization page.

        #{page_type_guidance(page_type)}

        Organization: #{@organization.name}
        Description: #{@org_data[:description]}
        #{features.present? ? "Known features:\n#{features.map { |f| "- #{f['title']}: #{f['description']}" }.join("\n")}" : 'Infer 3-4 key features from the description.'}

        AVAILABLE TAGS:
        {% features %}
        {% feature icon="rocket" title="Feature Name" %}Short description{% endfeature %}
        {% endfeatures %}

        VALID ICONS (use ONLY these exact names):
        lightning, code, codeblock, lock, cog, book, heart, send, mail,
        link, search, comment, fire, lightbulb, tag, team, organization, tools-line,
        palette-line, stack-line, badge, connect, bold, info, help, pencil, setting, sparkle-heart,
        dashboard-line, group-2-line, user-line, flashlight-line, external-link, checkmark, eye
        Do NOT use emoji characters or FontAwesome names as icons.

        RULES:
        - Start with a ## heading (under 10 words)
        - Include EXACTLY 3 or 6 features (not 4, not 5 — either 3 or 6)
        - Each description under 30 words, benefit-led not feature dumps
        - ONLY use icons from the valid list above or emoji. No FontAwesome names.
        - Output ONLY the section markdown, no explanations, no code blocks
      PROMPT
    end

    def build_social_proof_section_prompt
      testimonials = @org_data[:testimonials]
      return nil if testimonials.blank?

      quotes_list = testimonials.map { |t| "- \"#{t['text'] || t[:text]}\" — #{t['author'] || t[:author]}, #{t['role'] || t[:role]}" }.join("\n")

      <<~PROMPT
        Format these REAL testimonials into a section for "#{@organization.name}"'s DEV.to page.

        REAL TESTIMONIALS (use these EXACTLY — do NOT invent new ones):
        #{quotes_list}

        AVAILABLE TAG:
        {% quote author="Name" role="Title at Company" %}Testimonial text{% endquote %}

        RULES:
        - Start with a ## heading (under 10 words)
        - Format ONLY the real testimonials above into {% quote %} tags
        - Do NOT invent, fabricate, or embellish any quotes
        - Use the exact text, author, and role provided
        - NEVER leave placeholders like [Add logos here] — only output final content
        - Output ONLY the section markdown, no explanations, no code blocks
      PROMPT
    end

    def build_community_section_prompt
      return nil if @dev_posts.blank?

      posts_list = @dev_posts.map { |p| "- {% link #{p[:path].to_s.delete_prefix('/')} %}" }.join("\n")

      <<~PROMPT
        Write a community section for "#{@organization.name}"'s DEV.to page featuring these DEV posts.

        You MUST embed ALL posts using the EXACT tags shown:
        #{posts_list}

        RULES:
        - Start with a ## heading like "From the Community" or "What Developers Are Saying" (under 10 words)
        - Embed ALL posts using the EXACT {% link %} tags above. Copy them exactly.
        - Do NOT use markdown links [title](url). ONLY {% link %} tags.
        - You may add a brief 1-sentence intro
        - Output ONLY the section markdown, no explanations, no code blocks
      PROMPT
    end

    def build_org_posts_section_prompt
      return nil unless @has_org_posts

      <<~PROMPT
        Write an organization posts section for "#{@organization.name}"'s DEV.to page.

        Use this EXACT tag:
        {% org_posts #{@organization.slug} limit=5 sort=reactions %}

        RULES:
        - Start with a ## heading (under 10 words)
        - Include the {% org_posts %} tag EXACTLY as shown
        - You may add a 1-sentence intro
        - Output ONLY the section markdown, no explanations, no code blocks
      PROMPT
    end

    def build_team_section_prompt
      return nil unless @team_count > 1

      <<~PROMPT
        Write a team section for "#{@organization.name}"'s DEV.to page.

        Team size: #{@team_count} members on DEV

        Use this EXACT tag:
        {% org_team #{@organization.slug} limit=10 %}

        RULES:
        - Start with a ## heading (under 10 words)
        - Include the {% org_team %} tag EXACTLY as shown
        - You may add a 1-sentence intro
        - Output ONLY the section markdown, no explanations, no code blocks
      PROMPT
    end

    def build_youtube_section_prompt
      youtube_urls = @youtube_urls
      return nil if youtube_urls.empty?

      embeds = youtube_urls.map { |u| "{% youtube #{u} %}" }.join("\n")

      <<~PROMPT
        Write a video section for "#{@organization.name}"'s DEV.to page.

        Embed these YouTube videos using the EXACT tags:
        #{embeds}

        RULES:
        - Start with a ## heading (under 10 words)
        - Include the {% youtube %} tags EXACTLY as shown
        - You may add a 1-sentence intro
        - Output ONLY the section markdown, no explanations, no code blocks
      PROMPT
    end

    def build_lead_form_section_prompt
      lead_form_id = @active_lead_form&.id
      return nil unless lead_form_id

      <<~PROMPT
        Write a lead capture section for "#{@organization.name}"'s DEV.to page.

        Use this EXACT tag:
        {% org_lead_form #{lead_form_id} %}

        RULES:
        - Start with a ## heading (under 10 words)
        - Include the {% org_lead_form %} tag EXACTLY as shown
        - Add 1-2 sentences encouraging sign-up
        - Output ONLY the section markdown, no explanations, no code blocks
      PROMPT
    end

    def build_cta_section_prompt
      primary_link = @org_data[:links]&.first
      page_type = @org_data[:page_type] || "developer"

      <<~PROMPT
        Write a final call-to-action section for "#{@organization.name}"'s DEV.to page.

        #{page_type_guidance(page_type)}

        Organization: #{@organization.name}
        Primary link: #{primary_link ? "#{primary_link[:label]}: #{primary_link[:url]}" : 'none'}

        AVAILABLE TAG:
        {% offer link="URL" button="Button Text" %}Description{% endoffer %}

        GOOD offer: {% offer link="https://twilio.com/docs" button="Start Building" %}Get your API key and send your first message in under 5 minutes{% endoffer %}
        BAD offer: {% offer link="https://github.com/twilio" button="Github.com" %}Github.com{% endoffer %}

        RULES:
        - Start with a ## heading (under 10 words) — a closing value statement
        - Include ONE {% offer %} CTA
        - Use action verbs: "Get Started", "View Docs", "Try the API". NEVER "Submit" or "Learn More".
        - Add 1-2 sentences of persuasive closing text
        - NEVER use markdown links [text](url) — use {% offer %}
        - Output ONLY the section markdown, no explanations, no code blocks
      PROMPT
    end

    # --- QA Pipeline ---

    VALID_SVG_ICONS = %w[
      lightning code codeblock lock cog book heart send mail
      link search comment fire lightbulb tag team organization tools-line
      palette-line stack-line badge connect bold info help pencil setting sparkle-heart
      dashboard-line group-2-line user-line flashlight-line external-link checkmark eye
    ].freeze

    def qa_review(markdown)
      # Step 1: Fix broken icons deterministically
      markdown = fix_broken_icons(markdown)

      # Step 2: Replace emoji/invalid icons with valid SVG icons
      markdown = fix_emoji_icons(markdown)

      # Step 3: Fix bad embed tags (non-embeddable URLs → offer tags, channel URLs → remove)
      markdown = fix_bad_embeds(markdown)

      # Step 3b: Remove low-effort offer tags (domain-only button/description)
      markdown = fix_lazy_offers(markdown)

      # Step 4: Remove tags that would render empty
      markdown = remove_empty_tags(markdown)

      # Step 5: Strip unsupported markdown (checkboxes)
      markdown = fix_unsupported_markdown(markdown)

      # Step 6: Enforce 3 or 6 feature cards
      markdown = enforce_feature_count(markdown)

      # Step 7: Convert raw markdown links to offer tags
      markdown = convert_markdown_links_to_offers(markdown)

      # Step 8: Inject missing post embeds (always last — can't be undone by AI)
      markdown = inject_missing_posts(markdown)

      markdown
    rescue StandardError => e
      Rails.logger.warn("OrgPageGenerator QA review failed, using original: #{e.message}")
      markdown
    end

    def fix_broken_icons(markdown)
      html = render_markdown(markdown)
      broken = html.scan(/<!-- SVG file not found: '([^']+)' -->/).map { |m| m[0].delete_suffix(".svg") }
      return markdown if broken.empty?

      Rails.logger.info("OrgPageGenerator fixing #{broken.length} broken icon(s): #{broken.join(', ')}")
      broken.each do |icon_name|
        markdown = markdown.gsub(/icon="#{Regexp.escape(icon_name)}"/, 'icon="lightning"')
      end
      markdown
    end

    def fix_emoji_icons(markdown)
      # Replace any icon value that isn't a valid SVG icon name
      markdown.gsub(/icon="([^"]+)"/) do |match|
        icon_value = ::Regexp.last_match(1)
        if VALID_SVG_ICONS.include?(icon_value)
          match
        else
          Rails.logger.info("OrgPageGenerator replacing invalid icon '#{icon_value}' with 'star'")
          'icon="lightning"'
        end
      end
    end

    # Embeddable URL patterns — only these should use {% embed %} or {% youtube %}
    EMBEDDABLE_PATTERNS = [
      %r{youtube\.com/watch\?v=},     # YouTube video
      %r{youtu\.be/[\w-]+},           # YouTube short link
      %r{github\.com/[\w-]+/[\w-]+$}, # GitHub repo
      %r{dev\.to/},                   # DEV posts
    ].freeze

    # YouTube channel/playlist pages that aren't individual videos
    YOUTUBE_NON_VIDEO = %r{youtube\.com/(?:@|c/|channel/|user/|playlist)}i

    def fix_bad_embeds(markdown)
      markdown.gsub(/\{%\s*embed\s+(\S+)\s*%\}/) do |match|
        url = ::Regexp.last_match(1)

        # YouTube non-video URLs (channels, playlists) — remove entirely
        if url.match?(YOUTUBE_NON_VIDEO)
          Rails.logger.info("OrgPageGenerator removing non-video YouTube embed: #{url}")
          ""
        # Actual YouTube videos — convert to {% youtube %} tag
        elsif url.match?(%r{youtube\.com/watch|youtu\.be/})
          "{% youtube #{url} %}"
        # Embeddable URLs — keep as embed
        elsif EMBEDDABLE_PATTERNS.any? { |p| url.match?(p) }
          match
        # Non-embeddable URLs (docs, marketing pages, etc.) — convert to offer
        else
          label = URI.parse(url).host&.sub(/\Awww\./, "")&.capitalize || "Visit"
          Rails.logger.info("OrgPageGenerator converting non-embeddable embed to offer: #{url}")
          "{% offer link=\"#{url}\" button=\"#{label}\" %}#{label}{% endoffer %}"
        end
      rescue URI::InvalidURIError
        match
      end.gsub(/\n{3,}/, "\n\n")
    end

    def fix_lazy_offers(markdown)
      # Remove offer tags where button text or description is just a domain name
      markdown.gsub(/\{%\s*offer\s+link="([^"]+)"\s+button="([^"]+)"\s*%\}(.*?)\{%\s*endoffer\s*%\}/m) do |match|
        url = ::Regexp.last_match(1)
        button = ::Regexp.last_match(2).strip
        description = ::Regexp.last_match(3).strip

        # Detect lazy patterns: button or description is just a domain, URL, or single word
        is_lazy = button.match?(/\A[\w.-]+\.(com|io|org|dev|co)\z/i) ||
                  description.match?(/\A[\w.-]+\.(com|io|org|dev|co)\z/i) ||
                  button == description

        if is_lazy
          Rails.logger.info("OrgPageGenerator removing lazy offer: button=#{button} desc=#{description}")
          ""
        else
          match
        end
      end.gsub(/\n{3,}/, "\n\n")
    end

    def fix_unsupported_markdown(markdown)
      # Convert checkbox syntax [ ] and [x] to plain list items
      markdown.gsub(/^\s*\[[ x]\]\s*/i, "- ")
    end

    def enforce_feature_count(markdown)
      return markdown unless markdown.include?("{% features %}")

      feature_blocks = markdown.scan(/\{%\s*feature\s[^%]*%\}.*?\{%\s*endfeature\s*%\}/m)
      count = feature_blocks.length
      return markdown if count == 0 || count == 3 || count == 6

      target = count <= 3 ? count : (count <= 5 ? 3 : 6)
      return markdown if target == count

      Rails.logger.info("OrgPageGenerator trimming features from #{count} to #{target}")
      to_remove = feature_blocks[target..]
      to_remove.each { |block| markdown = markdown.sub(block, "") }
      markdown.gsub(/\n{3,}/, "\n\n")
    end

    def remove_empty_tags(markdown)
      has_org_posts = @has_org_posts
      has_team = @team_count > 1
      has_lead_form = @has_lead_form

      unless has_org_posts
        # Remove org_posts tags and their section headings
        markdown = markdown.gsub(/^##[^\n]*\n+\{%\s*org_posts\s[^%]*%\}\s*/m, "")
        markdown = markdown.gsub(/\{%\s*org_posts\s[^%]*%\}\s*/, "")
      end

      unless has_team
        markdown = markdown.gsub(/^##[^\n]*\n+\{%\s*org_team\s[^%]*%\}\s*/m, "")
        markdown = markdown.gsub(/\{%\s*org_team\s[^%]*%\}\s*/, "")
      end

      unless has_lead_form
        markdown = markdown.gsub(/\{%\s*org_lead_form\s[^%]*%\}\s*/, "")
      end

      # Remove {% youtube %} tags with non-YouTube URLs (AI sometimes puts random URLs in youtube tags)
      markdown.gsub(/\{%\s*youtube\s+(\S+)\s*%\}/) do |match|
        url = ::Regexp.last_match(1)
        if url.match?(%r{youtube\.com|youtu\.be})
          match # keep valid YouTube embeds
        else
          "" # remove non-YouTube from youtube tags
        end
      end
    end

    def convert_markdown_links_to_offers(markdown)
      # Convert standalone markdown links [text](url) to {% offer %} tags
      # Only converts links that are on their own line (not inline in a sentence)
      markdown.gsub(/^[-*]?\s*\[([^\]]+)\]\((https?:\/\/[^\)]+)\)\s*$/m) do
        text = ::Regexp.last_match(1)
        url = ::Regexp.last_match(2)
        # Skip DEV post links (those are handled by inject_missing_posts)
        if url.include?(Settings::General.app_domain)
          ::Regexp.last_match(0)
        else
          "{% offer link=\"#{url}\" button=\"#{text}\" %}#{text}{% endoffer %}"
        end
      end
    end

    def inject_missing_posts(markdown)
      return markdown if @dev_posts.blank?

      missing = @dev_posts.reject do |post|
        path = post[:path].to_s.delete_prefix("/")
        # Only consider it embedded if there's an actual liquid tag for it, not just a markdown link
        markdown.match?(/\{%\s*(?:link|embed|post)\s+[^\}]*#{Regexp.escape(path)}/)
      end
      return markdown if missing.empty?

      Rails.logger.info("OrgPageGenerator injecting #{missing.length} missing post embed(s)")

      # Also strip any plain markdown links to these posts (AI sometimes writes [title](url) instead of embed)
      missing.each do |post|
        path = post[:path].to_s.delete_prefix("/")
        markdown = markdown.gsub(/\[([^\]]*)\]\([^\)]*#{Regexp.escape(path)}[^\)]*\)/, "")
      end

      # Check if there's already a community section heading
      section_exists = markdown.match?(/^##.*(?:community|dev\b|written|saying)/im)

      # Use {% link path %} for DEV posts — does a direct DB lookup, no HTTP validation needed
      post_tags = missing.map { |p| "{% link #{p[:path].to_s.delete_prefix('/')} %}" }.join("\n\n")

      if section_exists
        # Append to the existing section (after the heading line)
        markdown.sub(/^(##.*(?:community|dev\b|written|saying).*)$/im, "\\1\n\n#{post_tags}")
      else
        # Add a new section at the end
        markdown.rstrip + "\n\n## From the DEV Community\n\n#{post_tags}\n"
      end
    end

    # detect_issues and build_qa_fix_prompt removed — all QA is now deterministic

    def render_markdown(markdown)
      renderer = ContentRenderer.new(markdown, source: @organization, user: nil)
      result = renderer.process
      result.processed_html
    end

    def clean_response(response)
      return "" if response.blank?

      cleaned = response.strip
      cleaned = cleaned.gsub(/^(Here is|I have generated|Generated content:)/i, "").strip
      cleaned = cleaned.gsub(/^(Here is the page:)/i, "").strip
      cleaned = cleaned.gsub(/^(```markdown|```|`)/, "").strip
      cleaned = cleaned.gsub(/(```markdown|```|`)$/, "").strip
      CGI.unescapeHTML(cleaned)
    end

    def build_generate_prompt
      guide = Ai::LiquidTagGuide.guide_text
      supplement = org_tag_supplement
      example = load_example_page

      dev_posts_context = if @dev_posts.present?
                            posts_list = @dev_posts.map { |p| "- \"#{p[:title]}\" — embed with: {% link #{p[:path].to_s.delete_prefix('/')} %}" }.join("\n")
                            "The user selected these DEV posts to feature. You MUST embed each one using the EXACT {% link %} tag shown below. Copy the tag exactly as written — do NOT use markdown links like [title](url):\n#{posts_list}"
                          else
                            "No DEV posts available."
                          end

      has_team = @organization.users.any?
      has_lead_form = @has_lead_form
      page_type = @org_data[:page_type] || "developer"
      page_type_instruction = page_type_guidance(page_type)

      <<~PROMPT
        You are a page designer for DEV.to organization pages.
        NEVER invent liquid tags. ONLY use tags explicitly listed in the reference below.
        The ONLY valid liquid tags are: features/feature, quote, offer, org_posts, org_team, org_lead_form, slides/slide, row/col, cta, feed, embed, link, youtube, github, and standard markdown.
        Tags like {% forem %}, {% banner %}, {% hero %}, {% section %}, {% card %}, {% grid %}, {% button %} do NOT exist and will cause errors.

        PAGE TYPE: #{page_type}
        #{page_type_instruction}

        <context>
        Organization name: #{@organization.name}
        Organization slug: #{@organization.slug}
        Tagline: #{@org_data[:title]}
        Description: #{@org_data[:description]}
        Key links: #{@org_data[:links]&.map { |l| "#{l[:label]}: #{l[:url]}" }&.join(", ")}
        Has team members on DEV: #{has_team}
        Has lead capture form: #{has_lead_form}

        Featured DEV posts:
        #{dev_posts_context}

        #{@org_data[:testimonials].present? ? "Real testimonials (use ONLY these in {% quote %} tags — do NOT invent quotes):\n#{@org_data[:testimonials].map { |t| "- \"#{t['text'] || t[:text]}\" — #{t['author'] || t[:author]}, #{t['role'] || t[:role]}" }.join("\n")}" : "No real testimonials available. Do NOT use {% quote %} tags — never fabricate testimonials."}
        </context>

        <reference_material>
        DEV EDITOR GUIDE & LIQUID TAG REFERENCE:
        #{guide}

        ORG PAGE TAG SUPPLEMENT (preferred tags for org pages):
        #{supplement}
        </reference_material>

        <example_output>
        Study this gold-standard example for correct liquid tag syntax, section structure, and tone:
        #{example}
        </example_output>

        OUTPUT RULES:
        - WORD COUNT: Aim for 300-600 words total. Headlines under 10 words. Feature descriptions under 30 words. Content must be skimmable — users read only ~28% of words on a page.
        - CTA PLACEMENT: Place {% offer %} tags in THREE positions: (1) hero/top section, (2) mid-page after features or social proof, (3) bottom of page as final CTA. Repeat the SAME primary action — one consistent CTA converts 30% better than multiple different CTAs.
        - CTA LANGUAGE: Use action verbs: "Get Started", "View Docs", "Try the API", "See It in Action". NEVER use "Submit", "Learn More", or "Click Here".
        - NEVER use raw markdown links like [text](url). Use {% offer %} for external links, {% link %} for DEV posts, {% youtube VIDEO_URL %} for YouTube videos.
        - NEVER use {% embed %} for docs pages, marketing pages, or YouTube channel URLs. Only use {% embed %} for GitHub repos. Use {% offer %} for all other external links.
        - {% youtube %} ONLY works with actual video URLs (youtube.com/watch?v=... or youtu.be/...). Channel pages and playlist pages will NOT embed.
        - ONLY embed YouTube videos if actual YouTube URLs are listed in the supplement above. NEVER guess or invent YouTube URLs.
        - If DEV posts were selected above, you MUST embed ALL of them using the EXACT {% link %} tags shown. Do NOT convert them to markdown links.
        - If a tag is marked "DO NOT USE" in the supplement, do NOT include it — it would render empty.
        - Pick sections based on available content. An empty section is worse than no section. Aim for 5-8 sections.
        - Use the org slug "#{@organization.slug}" for org_posts and org_team tags.
        - Use ## headings to separate sections.
        - Do NOT use {% row %}/{% col %} layouts — keep the page simple and single-column.
        - Output raw markdown only, no explanations or commentary.
        - Do NOT wrap output in markdown code blocks.
        - NEVER invent tags. ONLY use tags from the reference above.
        - NEVER leave placeholders like [Add logos here], [Insert image], [TODO], etc. Only output final, publishable content. If you don't have the content for something, omit that section entirely rather than leaving a placeholder.
      PROMPT
    end

    def build_iterate_prompt(current_markdown, instruction)
      guide = Ai::LiquidTagGuide.guide_text

      <<~PROMPT
        You are editing an existing DEV.to organization page for #{@organization.name}.

        Current page markdown:
        #{current_markdown}

        User feedback: #{instruction}

        DEV EDITOR GUIDE & LIQUID TAG REFERENCE:
        #{guide}

        ORG PAGE TAG SUPPLEMENT:
        #{org_tag_supplement}

        Update the page according to the user's feedback. Same rules apply:
        - ONLY use liquid tags explicitly listed above. NEVER invent tags. Tags like {% forem %}, {% banner %}, {% hero %}, {% section %}, {% card %}, {% grid %}, {% button %} do NOT exist.
        - The ONLY valid liquid tags are: features/feature, quote, offer, org_posts, org_team, org_lead_form, slides/slide, row/col, cta, feed, link, youtube, github, and standard markdown.
        - To embed a DEV post: {% link username/article-slug %}
        - To embed a YouTube video: {% youtube VIDEO_URL %}
        - Use the org slug "#{@organization.slug}" for org_posts and org_team tags
        - Output raw markdown only, no explanations
        - Do NOT wrap output in markdown code blocks
      PROMPT
    end

    def build_fix_prompt(broken_markdown, error_message)
      <<~PROMPT
        The following markdown for a DEV.to organization page has a syntax error:

        #{broken_markdown}

        Error: #{error_message}

        Fix the liquid tag syntax error and return the corrected markdown.
        REMOVE any unknown liquid tags entirely — replace them with plain markdown.
        The ONLY valid liquid tags are: features/feature, quote, offer, org_posts, org_team, org_lead_form, slides/slide, row/col, cta, feed.
        Output raw markdown only, no explanations.
        Do NOT wrap output in markdown code blocks.
      PROMPT
    end

    def page_type_guidance(page_type)
      case page_type
      when "developer"
        <<~GUIDANCE
          FRAMEWORK: PAS (Problem-Agitation-Solution). Start with the developer's pain point, highlight the friction, present the product as the solution.
          TONE: Technical, concise, show-don't-tell. Write like documentation, not marketing.
          SECTION ORDER: Hero (problem + solution) → Features (technical capabilities) → Social proof (usage metrics, logos) → Getting started/Docs → Final CTA
          GOOD EXAMPLES: "REST APIs with 99.9% uptime", "Ship in minutes, not days", "View the Docs"
          AVOID: "Revolutionary", "game-changing", "world-class", "leverage", marketing fluff, buzzwords, superlatives without proof, feature dumps without benefits
        GUIDANCE
      when "marketing"
        <<~GUIDANCE
          FRAMEWORK: AIDA (Attention-Interest-Desire-Action). Hero grabs Attention, Features build Interest, Social Proof creates Desire, CTA drives Action.
          TONE: Polished, benefit-focused, transformation narrative. Focus on outcomes not features.
          SECTION ORDER: Hero (transformation promise) → Social proof/logos → Features (benefit-led, not feature-led) → Testimonials → Getting started → Final CTA
          GOOD EXAMPLES: "Build in a weekend. Scale to millions.", "Trusted by 10,000 companies", "Get Started Free"
          AVOID: Feature dumps, jargon, self-congratulation, generic claims without specifics
        GUIDANCE
      when "community"
        <<~GUIDANCE
          FRAMEWORK: StoryBrand (visitor as hero). The visitor is the hero, the org is the guide. The org is NOT the star — the visitor's journey is.
          TONE: Warm, inclusive, "we" language. Collaborative and inviting.
          SECTION ORDER: Hero (community welcome) → Community content (posts, discussions) → Team members → How to contribute → Testimonials → Join CTA
          GOOD EXAMPLES: "Join thousands of developers building together", "Share what you're working on", "Welcome to the community"
          AVOID: Corporate speak, self-congratulation, exclusionary language, talking AT people instead of WITH them
        GUIDANCE
      when "talent"
        <<~GUIDANCE
          FRAMEWORK: Authentic voice. People-first, specific culture details over platitudes.
          TONE: Authentic, inspiring, people-first. Show real culture, not stock-photo energy.
          SECTION ORDER: Hero (why join us) → Team members → Engineering values/culture → What you'll work on → Testimonials from team → Open roles CTA
          GOOD EXAMPLES: "We ship to production 50 times a day", "Our engineers choose their own tools"
          AVOID: "We're like a family", "fast-paced environment", "competitive salary", vague platitudes, listing perks without context
        GUIDANCE
      else
        ""
      end
    end

    def org_tag_supplement
      lead_form_id = @active_lead_form&.id
      has_org_posts = @has_org_posts
      has_team = @team_count > 1
      youtube_urls = @youtube_urls

      parts = []
      parts << <<~PART
        These are the preferred liquid tags for organization pages:

        ## Feature Grid (2-6 highlights)
        {% features %}
        {% feature icon="rocket" title="Feature Name" %}Short description{% endfeature %}
        {% endfeatures %}

        IMPORTANT: The icon attribute MUST be one of these valid icon names, or an emoji character:
        Valid SVG icons: rocket, lightning, code, codeblock, lock, cog, book, heart, send, mail,
        link, search, comment, fire, lightbulb, star, tag, team, organization, tools-line,
        palette-line, stack-line, badge, connect, bold, info, help, pencil, setting, sparkle-heart,
        dashboard-line, group-2-line, user-line, flashlight-line, external-link, checkmark, globe, eye
        Do NOT use emoji characters or FontAwesome names like "code-branch", "shield-alt", "cubes", "wrench" — they won't work.

        ## Testimonial Quote
        {% quote author="Name" role="Title" rating=5 %}Testimonial text{% endquote %}

        ## Call-to-Action Offer
        {% offer link="https://example.com" button="Get Started" %}CTA description{% endoffer %}
      PART

      if has_org_posts
        parts << "## Organization Posts (this org HAS published articles — use this)\n{% org_posts #{@organization.slug} limit=5 sort=reactions %}"
      else
        parts << "## Organization Posts — DO NOT USE. This org has zero published articles on DEV, so {% org_posts %} would render an empty section."
      end

      if has_team
        parts << "## Organization Team (this org has #{@team_count} team members — use this)\n{% org_team #{@organization.slug} limit=10 %}"
      else
        parts << "## Organization Team — DO NOT USE. This org has only 1 member, so {% org_team %} would look empty."
      end

      parts << "## Lead Capture Form\n{% org_lead_form #{lead_form_id} %}" if lead_form_id

      if youtube_urls.any?
        parts << "## Embed YouTube Videos (found in provided URLs — use these)\n" + youtube_urls.map { |u| "{% youtube #{u} %}" }.join("\n")
      else
        parts << "## YouTube Embeds — DO NOT USE unless a YouTube URL was provided in the links above. Do NOT invent or guess YouTube URLs."
      end

      parts << <<~PART
        ## Image Carousel
        {% slides %}
        {% slide image="url" alt="text" title="Title" %}
        {% endslides %}

        ## Grid Layout
        {% row %}
        {% col span=2 %}Left column{% endcol %}
        {% col %}Right column{% endcol %}
        {% endrow %}

        ## Universal Embed (preferred — works with any URL)
        {% embed https://dev.to/username/article-slug %}
        {% embed https://www.youtube.com/watch?v=VIDEO_ID %}
        {% embed https://github.com/org/repo %}
      PART

      parts.join("\n\n")
    end

    def load_example_page
      self.class.example_page_content
    end

    def self.example_page_content
      @example_page_content ||= begin
        File.read(Rails.root.join("app/services/ai/org_page_example.md"))
      rescue Errno::ENOENT
        ""
      end
    end

    def extract_youtube_urls
      return [] if @org_data[:links].blank?

      @org_data[:links].filter_map do |link|
        url = link[:url].to_s
        url if url.match?(%r{(youtube\.com/watch|youtu\.be/)})
      end
    end
  end
end
