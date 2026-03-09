module Ai
  class OrgPageGenerator
    VERSION = "1.0"
    MAX_RETRIES = 3

    def initialize(organization:, org_data:, dev_posts: [])
      @organization = organization
      @org_data = org_data
      @dev_posts = dev_posts
      @ai_client = Ai::Base.new(wrapper: self, affected_content: organization)
    end

    def generate
      markdown = generate_with_retry(build_generate_prompt)
      html = render_markdown(markdown)
      { markdown: markdown, html: html }
    end

    def iterate(current_markdown:, instruction:)
      prompt = build_iterate_prompt(current_markdown, instruction)
      markdown = generate_with_retry(prompt)
      html = render_markdown(markdown)
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
      cleaned.gsub(/(```markdown|```|`)$/, "").strip
    end

    def build_generate_prompt
      guide = Ai::LiquidTagGuide.guide_text
      supplement = org_tag_supplement

      dev_posts_context = if @dev_posts.present?
                            @dev_posts.map { |p| "- \"#{p[:title]}\" (#{p[:reactions]} reactions) — #{URL.url}#{p[:path]}" }.join("\n")
                          else
                            "No DEV posts available."
                          end

      has_team = @organization.users.any?
      has_lead_form = @organization.lead_forms.active.any?

      <<~PROMPT
        You are a page designer for DEV.to organization pages.
        Generate a beautiful, professional markdown page using liquid tags for #{@organization.name}.

        CONTEXT:
        - Organization name: #{@organization.name}
        - Organization slug: #{@organization.slug}
        - Tagline: #{@org_data[:title]}
        - Description: #{@org_data[:description]}
        - Key links: #{@org_data[:links]&.map { |l| "#{l[:label]}: #{l[:url]}" }&.join(", ")}
        - Has team members on DEV: #{has_team}
        - Has lead capture form: #{has_lead_form}

        Featured DEV posts:
        #{dev_posts_context}

        DEV EDITOR GUIDE & LIQUID TAG REFERENCE:
        #{guide}

        ORG PAGE TAG SUPPLEMENT (preferred tags for org pages):
        #{supplement}

        RULES:
        - Only use tags from the references above — no invented syntax
        - Pick sections based on available content (skip what doesn't apply)
        - Use the org slug "#{@organization.slug}" for org_posts and org_team tags
        - Keep text concise and professional
        - Use ## headings to separate sections
        - Output raw markdown only, no explanations or commentary
        - Do NOT wrap output in markdown code blocks
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
        - Only use tags from the references above
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
        Only use valid liquid tags. Output raw markdown only, no explanations.
        Do NOT wrap output in markdown code blocks.
      PROMPT
    end

    def org_tag_supplement
      lead_form_id = @organization.lead_forms.active.first&.id

      <<~SUPPLEMENT
        These are the preferred liquid tags for organization pages:

        ## Feature Grid (2-6 highlights)
        {% features %}
        {% feature icon="rocket" title="Feature Name" %}Short description{% endfeature %}
        {% endfeatures %}

        ## Testimonial Quote
        {% quote author="Name" role="Title" rating=5 %}Testimonial text{% endquote %}

        ## Call-to-Action Offer
        {% offer link="https://example.com" button="Get Started" %}CTA description{% endoffer %}

        ## Organization Posts
        {% org_posts #{@organization.slug} limit=5 sort=reactions %}

        ## Organization Team
        {% org_team #{@organization.slug} limit=10 %}

        #{lead_form_id ? "## Lead Capture Form\n{% org_lead_form #{lead_form_id} %}" : ""}

        ## Image Carousel
        {% slides %}
        {% slide image="url" alt="text" title="Title" %}
        {% endslides %}

        ## Grid Layout
        {% row %}
        {% col span=2 %}Left column{% endcol %}
        {% col %}Right column{% endcol %}
        {% endrow %}
      SUPPLEMENT
    end
  end
end
