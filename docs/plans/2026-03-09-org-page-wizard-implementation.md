# AI-Powered Org Page Wizard — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a 3-step Gemini-powered wizard at `/org-wizard/:slug` that crawls URLs, mines DEV content, and generates org pages using rich liquid tags.

**Architecture:** Hybrid Rails controller (routes + auth + JSON endpoints) + single Preact component (client-side step transitions). Two new services (`Ai::OrgPageCrawler`, `Ai::OrgPageGenerator`) following existing `Ai::Base` patterns. Shared `Ai::LiquidTagGuide` module extracted from `EditorHelperService`.

**Tech Stack:** Rails 7, Preact, Gemini API (`gemini-2.5-pro`), MetaInspector, MiniMagick, RSpec, FactoryBot

**Design doc:** `docs/plans/2026-03-09-org-page-wizard-design.md`

---

### Task 1: Extract Shared Liquid Tag Guide Module

Extract the guide-building logic from `Ai::EditorHelperService` into a reusable module so both the editor chatbot and the org page wizard use the same liquid tag reference.

**Files:**
- Create: `app/services/ai/liquid_tag_guide.rb`
- Modify: `app/services/ai/editor_helper_service.rb:24-73`
- Test: `spec/services/ai/liquid_tag_guide_spec.rb`
- Test: `spec/services/ai/editor_helper_service_spec.rb` (verify still passes)

**Step 1: Write the failing test**

Create `spec/services/ai/liquid_tag_guide_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe Ai::LiquidTagGuide do
  describe ".guide_text" do
    it "returns cached guide text containing liquid tag syntax" do
      result = described_class.guide_text
      expect(result).to be_a(String)
      expect(result).to include("embed")
      expect(result.length).to be > 100
    end

    it "caches the result" do
      described_class.guide_text
      expect(Rails.cache).to have_received(:fetch).with("ai:liquid_tag_guide", expires_in: 12.hours)
    end
  end
end
```

Note: The cache test requires `allow(Rails.cache).to receive(:fetch).and_call_original` in a before block.

**Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/services/ai/liquid_tag_guide_spec.rb`
Expected: FAIL — `uninitialized constant Ai::LiquidTagGuide`

**Step 3: Implement the module**

Create `app/services/ai/liquid_tag_guide.rb`:

```ruby
module Ai
  module LiquidTagGuide
    CACHE_KEY = "ai:liquid_tag_guide"
    CACHE_EXPIRY = 12.hours

    def self.guide_text
      Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_EXPIRY) do
        build_guide
      end
    end

    def self.build_guide
      guide_path = Rails.root.join("app/views/pages/_editor_guide_text.en.html.erb")
      url_embeds_path = Rails.root.join("app/views/pages/_supported_url_embeds_list.en.html.erb")
      nonurl_embeds_path = Rails.root.join("app/views/pages/_supported_nonurl_embeds_list.en.html.erb")

      raw_guide = File.read(guide_path)
      raw_url_embeds = File.read(url_embeds_path)
      raw_nonurl_embeds = File.read(nonurl_embeds_path)

      clean_guide = strip_erb_and_html(raw_guide)

      clean_url_embeds = raw_url_embeds.gsub(/<%=.*?%>/, "").gsub(/<%.*?%>/, "")
        .gsub(/<ul[^>]*>/, "\n")
        .gsub("</ul>", "\n")
        .gsub(/<li[^>]*>/, "- ")
        .gsub("</li>", "\n")
        .gsub(/<h4[^>]*>/, "\n### ")
        .gsub("</h4>", "\n")
        .gsub(/<p[^>]*>/, "\n")
        .gsub("</p>", "\n")
        .gsub(%r{<br\s*/?>}, "\n")
        .gsub(/<[^>]+>/, "")
        .gsub(/\n\s*\n\s*\n+/, "\n\n").strip

      clean_nonurl_embeds = raw_nonurl_embeds.gsub(/<%=.*?%>/, "").gsub(/<%.*?%>/, "")
        .gsub(/<h4[^>]*>/, "\n### ")
        .gsub("</h4>", "\n")
        .gsub(/<p[^>]*>/, "\n")
        .gsub("</p>", "\n")
        .gsub(%r{<br\s*/?>}, "\n")
        .gsub(/<pre[^>]*>/, "\n```\n")
        .gsub("</pre>", "\n```\n")
        .gsub(/<code[^>]*>/, "`")
        .gsub("</code>", "`")
        .gsub(/<[^>]+>/, "")
        .gsub(/\n\s*\n\s*\n+/, "\n\n").strip

      <<~GUIDE
        #{clean_guide}

        Supported URL Embeds:
        #{clean_url_embeds}

        Supported Non-URL (Block) Embeds:
        #{clean_nonurl_embeds}
      GUIDE
    end

    def self.strip_erb_and_html(raw)
      content_without_erb = raw.gsub(/<%=.*?%>/, "").gsub(/<%.*?%>/, "")
      ActionView::Base.full_sanitizer.sanitize(content_without_erb).gsub(/\s+/, " ").strip
    end

    private_class_method :build_guide, :strip_erb_and_html
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec rspec spec/services/ai/liquid_tag_guide_spec.rb`
Expected: PASS

**Step 5: Refactor EditorHelperService to use the shared module**

Modify `app/services/ai/editor_helper_service.rb` — replace lines 24-73 with:

```ruby
def prompt
  final_guide_text = Ai::LiquidTagGuide.guide_text

  article_context = ""
  # ... rest of method unchanged
```

**Step 6: Verify existing editor helper tests still pass**

Run: `bundle exec rspec spec/services/ai/editor_helper_service_spec.rb`
Expected: PASS

**Step 7: Commit**

```bash
git add app/services/ai/liquid_tag_guide.rb spec/services/ai/liquid_tag_guide_spec.rb app/services/ai/editor_helper_service.rb
git commit -m "Extract Ai::LiquidTagGuide from EditorHelperService for reuse"
```

---

### Task 2: Ai::OrgPageCrawler Service

Crawls provided URLs, extracts metadata, detects brand colors, and searches DEV for org content. No AI call needed.

**Files:**
- Create: `app/services/ai/org_page_crawler.rb`
- Test: `spec/services/ai/org_page_crawler_spec.rb`

**Reference files:**
- `app/services/open_graph.rb` — MetaInspector usage pattern
- `app/services/color/compare_hex.rb` — color manipulation

**Step 1: Write the failing test**

Create `spec/services/ai/org_page_crawler_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe Ai::OrgPageCrawler do
  let(:organization) { create(:organization, name: "Twilio") }
  let(:urls) { ["https://www.twilio.com"] }
  let(:service) { described_class.new(organization: organization, urls: urls) }

  describe "#crawl" do
    before do
      # Stub MetaInspector via OpenGraph
      mock_page = instance_double(MetaInspector,
                                  best_title: "Twilio - Communication APIs",
                                  description: "Cloud communications platform",
                                  best_url: "https://www.twilio.com",
                                  images: double(best: "https://www.twilio.com/og.png"),
                                  meta: { "theme-color" => "#F22F46" },
                                  meta_tags: { "name" => { "theme-color" => ["#F22F46"] } })
      allow(MetaInspector).to receive(:new).and_return(mock_page)
      allow(HTTParty).to receive(:get).and_return(double(body: "<html></html>"))
      allow(Rails.cache).to receive(:fetch).and_call_original
    end

    it "returns structured crawl data" do
      result = service.crawl
      expect(result).to include(
        title: "Twilio - Communication APIs",
        description: "Cloud communications platform",
        og_image: "https://www.twilio.com/og.png",
      )
    end

    it "detects brand color from meta theme-color" do
      result = service.crawl
      expect(result[:detected_color]).to eq("#F22F46")
    end

    it "searches DEV for related articles" do
      create(:article, title: "Getting Started with Twilio", published: true, positive_reactions_count: 10)
      result = service.crawl
      expect(result[:dev_posts]).to be_an(Array)
    end

    context "when URL is unreachable" do
      before do
        allow(HTTParty).to receive(:get).and_raise(StandardError, "Connection refused")
      end

      it "returns graceful error data" do
        result = service.crawl
        expect(result[:error]).to be_present
        expect(result[:title]).to be_nil
      end
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/services/ai/org_page_crawler_spec.rb`
Expected: FAIL — `uninitialized constant Ai::OrgPageCrawler`

**Step 3: Implement the service**

Create `app/services/ai/org_page_crawler.rb`:

```ruby
module Ai
  class OrgPageCrawler
    VERSION = "1.0"

    def initialize(organization:, urls:)
      @organization = organization
      @urls = urls.select(&:present?).first(4)
    end

    def crawl
      site_data = crawl_urls
      dev_posts = search_dev_posts
      detected_color = detect_brand_color(site_data)

      {
        title: site_data[:title],
        description: site_data[:description],
        og_image: site_data[:og_image],
        links: site_data[:links],
        detected_color: detected_color,
        dev_posts: dev_posts
      }
    rescue StandardError => e
      Rails.logger.error("OrgPageCrawler failed: #{e.message}")
      { error: e.message, title: nil, description: nil, og_image: nil,
        links: [], detected_color: nil, dev_posts: search_dev_posts }
    end

    private

    def crawl_urls
      primary_url = @urls.first
      return {} if primary_url.blank?

      html = fetch_html(primary_url)
      page = MetaInspector.new(primary_url, document: html)

      {
        title: page.best_title,
        description: page.description || page.meta["og:description"],
        og_image: page.images.best,
        links: extract_key_links(page)
      }
    rescue StandardError => e
      Rails.logger.warn("Failed to crawl #{@urls.first}: #{e.message}")
      {}
    end

    def fetch_html(url)
      Rails.cache.fetch("org_crawler:#{url}", expires_in: 15.minutes) do
        response = HTTParty.get(url,
                                headers: { "User-Agent" => "#{Settings::Community.community_name} (#{URL.url})" },
                                timeout: 10)
        response&.body
      end
    end

    def extract_key_links(page)
      # Collect links from all provided URLs
      links = @urls.map do |url|
        { url: url, label: label_for_url(url) }
      end
      links.compact.uniq { |l| l[:url] }
    end

    def label_for_url(url)
      uri = URI.parse(url)
      path = uri.path.to_s.gsub(%r{^/|/$}, "")
      return "Website" if path.blank?

      path.split("/").first.capitalize
    rescue URI::InvalidURIError
      "Link"
    end

    def detect_brand_color(site_data)
      # Chain 1: Meta theme-color
      color = detect_from_meta_theme_color
      return color if valid_hex?(color)

      # Chain 2: OG image dominant color (via MiniMagick 1x1 resize)
      color = detect_from_image(site_data[:og_image])
      return color if valid_hex?(color)

      nil
    end

    def detect_from_meta_theme_color
      primary_url = @urls.first
      return nil if primary_url.blank?

      html = fetch_html(primary_url)
      page = MetaInspector.new(primary_url, document: html)

      # Check meta tags for theme-color
      theme_color = page.meta_tags.dig("name", "theme-color")&.first
      theme_color ||= page.meta["theme-color"]
      theme_color
    rescue StandardError
      nil
    end

    def detect_from_image(image_url)
      return nil if image_url.blank?

      tempfile = Down.download(image_url, max_size: 5 * 1024 * 1024)
      image = MiniMagick::Image.new(tempfile.path)
      image.resize "1x1"
      pixel = image.get_pixels.first&.first
      return nil unless pixel

      "#%02X%02X%02X" % pixel
    rescue StandardError
      nil
    end

    def search_dev_posts
      # Search for articles mentioning the org name or by the org
      articles_by_org = Article.published
        .where(organization_id: @organization.id)
        .order(positive_reactions_count: :desc)
        .limit(20)
        .select(:id, :title, :path, :positive_reactions_count, :comments_count, :published_at)

      articles_about_org = Article.published
        .search_optimized(@organization.name)
        .where.not(id: articles_by_org.map(&:id))
        .limit(10)
        .select(:id, :title, :path, :positive_reactions_count, :comments_count, :published_at)

      (articles_by_org + articles_about_org).map do |article|
        {
          id: article.id,
          title: article.title,
          path: article.path,
          reactions: article.positive_reactions_count,
          comments: article.comments_count,
          published_at: article.published_at&.iso8601
        }
      end
    rescue StandardError => e
      Rails.logger.warn("Failed to search DEV posts: #{e.message}")
      []
    end

    def valid_hex?(color)
      color.present? && color.match?(/\A#[0-9A-Fa-f]{6}\z/)
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec rspec spec/services/ai/org_page_crawler_spec.rb`
Expected: PASS

**Step 5: Add `down` gem if not present**

Check `Gemfile` for `down` gem (used for image download in color detection). If absent, use `HTTParty.get` + `Tempfile` instead. The `down` gem is cleaner but not required. Adjust implementation accordingly.

**Step 6: Commit**

```bash
git add app/services/ai/org_page_crawler.rb spec/services/ai/org_page_crawler_spec.rb
git commit -m "Add Ai::OrgPageCrawler for URL scraping and DEV content search"
```

---

### Task 3: Ai::OrgPageGenerator Service

Generates org page markdown via Gemini using crawled data and liquid tag reference.

**Files:**
- Create: `app/services/ai/org_page_generator.rb`
- Test: `spec/services/ai/org_page_generator_spec.rb`

**Reference files:**
- `app/services/ai/about_page_generator.rb` — retry pattern, response cleaning
- `app/services/ai/base.rb` — Gemini API interface
- `app/services/content_renderer.rb` — markdown validation

**Step 1: Write the failing test**

Create `spec/services/ai/org_page_generator_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe Ai::OrgPageGenerator do
  let(:organization) { create(:organization, name: "Twilio", slug: "twilio") }
  let(:org_data) do
    {
      title: "Twilio - Communication APIs",
      description: "Cloud communications platform for voice, SMS, and video",
      og_image: "https://www.twilio.com/og.png",
      links: [{ url: "https://www.twilio.com/docs", label: "Docs" }],
      detected_color: "#F22F46"
    }
  end
  let(:dev_posts) do
    [{ id: 1, title: "Getting Started with Twilio", path: "/twilio/getting-started", reactions: 42 }]
  end
  let(:service) { described_class.new(organization: organization, org_data: org_data, dev_posts: dev_posts) }

  describe "#generate" do
    let(:mock_markdown) do
      <<~MD
        ## Welcome to Twilio on DEV

        Twilio powers communication APIs for voice, SMS, and video.

        {% features %}
        {% feature icon="phone" title="Voice" %}Build voice experiences{% endfeature %}
        {% feature icon="message" title="SMS" %}Send and receive messages{% endfeature %}
        {% endfeatures %}

        {% offer link="https://www.twilio.com/docs" button="Explore Docs" %}
        Start building with Twilio's comprehensive documentation.
        {% endoffer %}
      MD
    end

    before do
      allow(Ai::Base).to receive(:new).and_return(double(call: mock_markdown))
    end

    it "returns generated markdown and rendered HTML" do
      result = service.generate
      expect(result[:markdown]).to include("Welcome to Twilio")
      expect(result[:html]).to be_present
    end

    it "validates markdown through ContentRenderer" do
      result = service.generate
      expect(result[:html]).to include("Twilio")
    end
  end

  describe "#iterate" do
    let(:current_markdown) { "## Old Content\n\nSome existing page." }
    let(:instruction) { "Make it more developer-focused" }
    let(:updated_markdown) { "## Developer Hub\n\nBuild with Twilio APIs." }

    before do
      allow(Ai::Base).to receive(:new).and_return(double(call: updated_markdown))
    end

    it "returns updated markdown based on user feedback" do
      result = service.iterate(current_markdown: current_markdown, instruction: instruction)
      expect(result[:markdown]).to include("Developer Hub")
    end
  end

  describe "retry on validation failure" do
    let(:ai_service) { double }
    let(:bad_markdown) { "{% broken_tag %}" }
    let(:good_markdown) { "## Welcome\n\nValid content here." }

    before do
      allow(Ai::Base).to receive(:new).and_return(ai_service)
      call_count = 0
      allow(ai_service).to receive(:call) do
        call_count += 1
        call_count == 1 ? bad_markdown : good_markdown
      end
      allow(Rails.logger).to receive(:warn)
    end

    it "retries when ContentRenderer raises" do
      result = service.generate
      expect(result[:markdown]).to include("Welcome")
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/services/ai/org_page_generator_spec.rb`
Expected: FAIL — `uninitialized constant Ai::OrgPageGenerator`

**Step 3: Implement the service**

Create `app/services/ai/org_page_generator.rb`:

```ruby
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

          # Validate through ContentRenderer
          render_markdown(markdown)
          return markdown
        rescue ContentRenderer::ContentParsingError => e
          retries += 1
          last_error = e.message
          Rails.logger.warn("OrgPageGenerator attempt #{retries} validation failed: #{e.message}")

          # Feed error back to AI for next attempt
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
      has_lead_form = @organization.lead_forms.active.any? rescue false

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
      supplement = org_tag_supplement

      <<~PROMPT
        You are editing an existing DEV.to organization page for #{@organization.name}.

        Current page markdown:
        #{current_markdown}

        User feedback: #{instruction}

        DEV EDITOR GUIDE & LIQUID TAG REFERENCE:
        #{guide}

        ORG PAGE TAG SUPPLEMENT:
        #{supplement}

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
      lead_form_id = (@organization.lead_forms.active.first&.id rescue nil)

      <<~SUPPLEMENT
        These are the preferred liquid tags for organization pages. Use them to build rich, visual pages:

        ## Feature Grid (use for 2-6 highlights about the org)
        {% features %}
        {% feature icon="rocket" title="Feature Name" %}Short description of this feature.{% endfeature %}
        {% feature icon="code" title="Another Feature" %}Another description here.{% endfeature %}
        {% endfeatures %}

        ## Testimonial Quote (use for social proof from the DEV community)
        {% quote author="Developer Name" role="Software Engineer" rating=5 %}
        This is what someone said about the org.
        {% endquote %}

        ## Call-to-Action Offer (use for docs, signup, or key links)
        {% offer link="https://example.com/docs" button="Get Started" %}
        A brief call-to-action description encouraging developers to take action.
        {% endoffer %}

        ## Organization Posts (shows the org's published DEV articles)
        {% org_posts #{@organization.slug} limit=5 sort=reactions %}

        ## Organization Team (shows team members on DEV)
        {% org_team #{@organization.slug} limit=10 %}

        #{lead_form_id ? "## Lead Capture Form\n{% org_lead_form #{lead_form_id} %}" : ""}

        ## Image/Resource Carousel
        {% slides %}
        {% slide image="https://example.com/image.png" alt="Description" title="Resource Title" %}
        {% endslides %}

        ## Grid Layout (use for side-by-side content)
        {% row %}
        {% col span=2 %}Left column content (wider){% endcol %}
        {% col %}Right column content{% endcol %}
        {% endrow %}

        ## Content Feed (alternative to org_posts, for tag-based feeds)
        {% feed tag=relevant_tag limit=5 sort=reactions %}
      SUPPLEMENT
    end
  end
end
```

**Step 4: Run test to verify it passes**

Run: `bundle exec rspec spec/services/ai/org_page_generator_spec.rb`
Expected: PASS (some tests may need adjustment based on ContentRenderer behavior with test markdown — adjust stubs as needed)

**Step 5: Commit**

```bash
git add app/services/ai/org_page_generator.rb spec/services/ai/org_page_generator_spec.rb
git commit -m "Add Ai::OrgPageGenerator for Gemini-powered org page creation"
```

---

### Task 4: Routes and OrgWizardController

**Files:**
- Modify: `config/routes.rb:359` (add wizard routes after org members route)
- Create: `app/controllers/org_wizard_controller.rb`
- Test: `spec/requests/org_wizard_spec.rb`

**Step 1: Write the failing request spec**

Create `spec/requests/org_wizard_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "OrgWizard" do
  let(:organization) { create(:organization) }
  let(:admin) { create(:user) }
  let(:non_admin) { create(:user) }

  before do
    create(:organization_membership, user: admin, organization: organization, type_of_user: "admin")
  end

  describe "GET /org-wizard/:slug" do
    it "renders for org admin" do
      sign_in admin
      get "/org-wizard/#{organization.slug}"
      expect(response).to have_http_status(:ok)
    end

    it "redirects unauthenticated users" do
      get "/org-wizard/#{organization.slug}"
      expect(response).to redirect_to(sign_up_path)
    end

    it "raises for non-admin" do
      sign_in non_admin
      expect { get "/org-wizard/#{organization.slug}" }.to raise_error(Pundit::NotAuthorizedError)
    end

    it "returns 404 for unknown slug" do
      sign_in admin
      expect { get "/org-wizard/nonexistent" }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "POST /org-wizard/:slug/crawl" do
    before { sign_in admin }

    it "returns crawled data as JSON" do
      mock_page = instance_double(MetaInspector,
                                  best_title: "Test Org",
                                  description: "A test",
                                  best_url: "https://test.com",
                                  images: double(best: nil),
                                  meta: {},
                                  meta_tags: { "name" => {} })
      allow(MetaInspector).to receive(:new).and_return(mock_page)
      allow(HTTParty).to receive(:get).and_return(double(body: "<html></html>"))

      post "/org-wizard/#{organization.slug}/crawl", params: { urls: ["https://test.com"] }, as: :json
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["title"]).to eq("Test Org")
    end
  end

  describe "POST /org-wizard/:slug/generate" do
    before do
      sign_in admin
      allow(Ai::Base).to receive(:new).and_return(double(call: "## Hello\n\nWelcome."))
    end

    it "returns generated markdown and HTML" do
      post "/org-wizard/#{organization.slug}/generate",
           params: { org_data: { title: "Test", description: "Desc" }, dev_posts: [] },
           as: :json
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["markdown"]).to include("Hello")
      expect(json["html"]).to be_present
    end
  end

  describe "POST /org-wizard/:slug/save" do
    before { sign_in admin }

    it "saves markdown to organization" do
      post "/org-wizard/#{organization.slug}/save",
           params: { markdown: "## Test Page", detected_color: "#FF0000" },
           as: :json
      expect(response).to have_http_status(:ok)
      organization.reload
      expect(organization.page_markdown).to eq("## Test Page")
      expect(organization.bg_color_hex).to eq("#FF0000")
    end
  end
end
```

**Step 2: Run test to verify it fails**

Run: `bundle exec rspec spec/requests/org_wizard_spec.rb`
Expected: FAIL — routing error

**Step 3: Add routes**

Modify `config/routes.rb` — add after line 359 (after `get ":slug/members"`):

```ruby
    # Org page wizard
    scope "org-wizard/:slug" do
      get  "/",         to: "org_wizard#show",     as: :org_wizard
      post "/crawl",    to: "org_wizard#crawl",    as: :org_wizard_crawl
      post "/generate", to: "org_wizard#generate", as: :org_wizard_generate
      post "/iterate",  to: "org_wizard#iterate",  as: :org_wizard_iterate
      post "/save",     to: "org_wizard#save",     as: :org_wizard_save
    end
```

**Step 4: Create the controller**

Create `app/controllers/org_wizard_controller.rb`:

```ruby
class OrgWizardController < ApplicationController
  before_action :authenticate_user!
  before_action :set_organization
  before_action :authorize_admin!

  def show
    @organization_json = {
      name: @organization.name,
      slug: @organization.slug,
      bg_color_hex: @organization.bg_color_hex,
      has_page: @organization.readme_page?
    }.to_json
  end

  def crawl
    urls = params[:urls].to_a.select(&:present?).first(4)
    crawler = Ai::OrgPageCrawler.new(organization: @organization, urls: urls)
    result = crawler.crawl
    render json: result
  end

  def generate
    org_data = params[:org_data]&.to_unsafe_h || {}
    dev_posts = params[:dev_posts]&.map(&:to_unsafe_h) || []

    generator = Ai::OrgPageGenerator.new(
      organization: @organization,
      org_data: org_data.deep_symbolize_keys,
      dev_posts: dev_posts.map(&:deep_symbolize_keys)
    )
    result = generator.generate
    render json: result
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def iterate
    org_data = params[:org_data]&.to_unsafe_h || {}
    dev_posts = params[:dev_posts]&.map(&:to_unsafe_h) || []

    generator = Ai::OrgPageGenerator.new(
      organization: @organization,
      org_data: org_data.deep_symbolize_keys,
      dev_posts: dev_posts.map(&:deep_symbolize_keys)
    )
    result = generator.iterate(
      current_markdown: params[:current_markdown].to_s,
      instruction: params[:instruction].to_s
    )
    render json: result
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def save
    markdown = params[:markdown].to_s
    detected_color = params[:detected_color]

    updates = { page_markdown: markdown }
    updates[:bg_color_hex] = detected_color if detected_color.present? && detected_color.match?(/\A#[0-9A-Fa-f]{6}\z/)

    if @organization.update(updates)
      render json: { success: true, redirect_url: "/#{@organization.slug}" }
    else
      render json: { error: @organization.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  private

  def set_organization
    @organization = Organization.find_by!(slug: params[:slug])
  end

  def authorize_admin!
    authorize @organization, :update?, policy_class: OrganizationPolicy
  end
end
```

**Step 5: Run tests**

Run: `bundle exec rspec spec/requests/org_wizard_spec.rb`
Expected: PASS

**Step 6: Commit**

```bash
git add config/routes.rb app/controllers/org_wizard_controller.rb spec/requests/org_wizard_spec.rb
git commit -m "Add OrgWizardController with routes for AI page generation wizard"
```

---

### Task 5: Rails View (Preact Mount Point)

**Files:**
- Create: `app/views/org_wizard/show.html.erb`
- Create: `app/views/layouts/org_wizard.html.erb` (optional: minimal layout without sidebar)

**Step 1: Create the view**

Create `app/views/org_wizard/show.html.erb`:

```erb
<div id="org-wizard-container"
     data-organization="<%= @organization_json %>"
     data-crawl-url="<%= org_wizard_crawl_path(@organization.slug) %>"
     data-generate-url="<%= org_wizard_generate_path(@organization.slug) %>"
     data-iterate-url="<%= org_wizard_iterate_path(@organization.slug) %>"
     data-save-url="<%= org_wizard_save_path(@organization.slug) %>"
     data-settings-url="<%= organization_settings_path(@organization.slug) %>">
</div>
<%= javascript_include_tag "OrgWizard", defer: true %>
```

**Step 2: Verify view renders**

Run the request spec again to confirm the view renders without error:
Run: `bundle exec rspec spec/requests/org_wizard_spec.rb`
Expected: PASS (the GET test should render the view)

**Step 3: Commit**

```bash
git add app/views/org_wizard/show.html.erb
git commit -m "Add org wizard Rails view with Preact mount point"
```

---

### Task 6: Preact Pack Entry Point

**Files:**
- Create: `app/javascript/packs/OrgWizard.jsx`

**Reference:** `app/javascript/packs/Onboarding.jsx` — same mount pattern

**Step 1: Create the pack file**

Create `app/javascript/packs/OrgWizard.jsx`:

```jsx
import { h, render } from 'preact';
import { getUserDataAndCsrfToken } from '@utilities/getUserDataAndCsrfToken';

HTMLDocument.prototype.ready = new Promise((resolve) => {
  if (document.readyState !== 'loading') {
    return resolve();
  }
  document.addEventListener('DOMContentLoaded', () => resolve());
  return null;
});

function renderWizard() {
  const container = document.getElementById('org-wizard-container');
  if (!container) return;

  const config = {
    organization: JSON.parse(container.dataset.organization),
    crawlUrl: container.dataset.crawlUrl,
    generateUrl: container.dataset.generateUrl,
    iterateUrl: container.dataset.iterateUrl,
    saveUrl: container.dataset.saveUrl,
    settingsUrl: container.dataset.settingsUrl,
  };

  import('../orgWizard/OrgWizard')
    .then(({ OrgWizard }) => {
      render(<OrgWizard {...config} />, container);
    })
    .catch((error) => {
      console.error('Unable to load OrgWizard', error);
    });
}

document.ready.then(
  getUserDataAndCsrfToken()
    .then(({ currentUser, csrfToken }) => {
      window.currentUser = currentUser;
      window.csrfToken = csrfToken;
      renderWizard();
    })
    .catch((error) => {
      console.error('Error getting user and CSRF Token', error);
    }),
);
```

**Step 2: Commit**

```bash
git add app/javascript/packs/OrgWizard.jsx
git commit -m "Add OrgWizard Preact pack entry point"
```

---

### Task 7: Preact OrgWizard Component — Step 1 (URL Input)

**Files:**
- Create: `app/javascript/orgWizard/OrgWizard.jsx`
- Create: `app/javascript/orgWizard/components/StepInput.jsx`

**Reference:** `app/javascript/onboarding/Onboarding.jsx` — multi-step pattern

**Step 1: Create the main OrgWizard component**

Create `app/javascript/orgWizard/OrgWizard.jsx`:

```jsx
import { h, Component } from 'preact';
import { StepInput } from './components/StepInput';
import { StepReview } from './components/StepReview';
import { StepPreview } from './components/StepPreview';
import { request } from '@utilities/http';

// States: input | crawling | review | generating | preview | iterating | saving | saved
export class OrgWizard extends Component {
  constructor(props) {
    super(props);
    this.state = {
      step: 'input',
      urls: [''],
      crawlData: null,
      selectedPosts: [],
      editedData: {},
      markdown: '',
      html: '',
      error: null,
    };
  }

  handleCrawl = async (urls) => {
    this.setState({ step: 'crawling', urls, error: null });

    try {
      const response = await request(this.props.crawlUrl, {
        method: 'POST',
        body: JSON.stringify({ urls }),
      });

      if (!response.ok) throw new Error('Failed to crawl URLs');

      const data = await response.json();

      if (data.error && !data.title) {
        this.setState({ step: 'input', error: data.error });
        return;
      }

      const topPosts = (data.dev_posts || []).slice(0, 5).map((p) => p.id);
      this.setState({
        step: 'review',
        crawlData: data,
        selectedPosts: topPosts,
        editedData: {
          title: data.title || '',
          description: data.description || '',
          detected_color: data.detected_color || '',
        },
      });
    } catch (err) {
      this.setState({ step: 'input', error: err.message });
    }
  };

  handleGenerate = async () => {
    this.setState({ step: 'generating', error: null });

    const { editedData, crawlData, selectedPosts } = this.state;
    const devPosts = (crawlData.dev_posts || []).filter((p) =>
      selectedPosts.includes(p.id),
    );

    try {
      const response = await request(this.props.generateUrl, {
        method: 'POST',
        body: JSON.stringify({
          org_data: {
            ...editedData,
            links: crawlData.links || [],
          },
          dev_posts: devPosts,
        }),
      });

      if (!response.ok) {
        const err = await response.json();
        throw new Error(err.error || 'Generation failed');
      }

      const result = await response.json();
      this.setState({
        step: 'preview',
        markdown: result.markdown,
        html: result.html,
      });
    } catch (err) {
      this.setState({ step: 'review', error: err.message });
    }
  };

  handleIterate = async (instruction) => {
    this.setState({ step: 'iterating', error: null });

    const { editedData, crawlData, selectedPosts, markdown } = this.state;
    const devPosts = (crawlData.dev_posts || []).filter((p) =>
      selectedPosts.includes(p.id),
    );

    try {
      const response = await request(this.props.iterateUrl, {
        method: 'POST',
        body: JSON.stringify({
          current_markdown: markdown,
          instruction,
          org_data: {
            ...editedData,
            links: crawlData.links || [],
          },
          dev_posts: devPosts,
        }),
      });

      if (!response.ok) {
        const err = await response.json();
        throw new Error(err.error || 'Iteration failed');
      }

      const result = await response.json();
      this.setState({
        step: 'preview',
        markdown: result.markdown,
        html: result.html,
      });
    } catch (err) {
      this.setState({ step: 'preview', error: err.message });
    }
  };

  handleSave = async () => {
    this.setState({ step: 'saving', error: null });

    try {
      const response = await request(this.props.saveUrl, {
        method: 'POST',
        body: JSON.stringify({
          markdown: this.state.markdown,
          detected_color: this.state.editedData.detected_color,
        }),
      });

      if (!response.ok) {
        const err = await response.json();
        throw new Error(err.error || 'Save failed');
      }

      const result = await response.json();
      window.location.href = result.redirect_url;
    } catch (err) {
      this.setState({ step: 'preview', error: err.message });
    }
  };

  handleStartOver = () => {
    this.setState({
      step: 'input',
      urls: [''],
      crawlData: null,
      selectedPosts: [],
      editedData: {},
      markdown: '',
      html: '',
      error: null,
    });
  };

  render() {
    const { organization } = this.props;
    const { step, error } = this.state;

    return (
      <div className="org-wizard crayons-card p-6 m-auto" style={{ maxWidth: '800px' }}>
        <h1 className="fs-2xl mb-2">
          Setting up {organization.name}&apos;s page
        </h1>

        {error && (
          <div className="crayons-notice crayons-notice--danger mb-4" role="alert">
            {error}
          </div>
        )}

        {(step === 'input' || step === 'crawling') && (
          <StepInput
            urls={this.state.urls}
            loading={step === 'crawling'}
            onSubmit={this.handleCrawl}
          />
        )}

        {(step === 'review' || step === 'generating') && (
          <StepReview
            crawlData={this.state.crawlData}
            editedData={this.state.editedData}
            selectedPosts={this.state.selectedPosts}
            loading={step === 'generating'}
            onEditData={(editedData) => this.setState({ editedData })}
            onTogglePost={(postId) => {
              const { selectedPosts } = this.state;
              const updated = selectedPosts.includes(postId)
                ? selectedPosts.filter((id) => id !== postId)
                : [...selectedPosts, postId];
              this.setState({ selectedPosts: updated });
            }}
            onGenerate={this.handleGenerate}
            onBack={this.handleStartOver}
          />
        )}

        {(step === 'preview' || step === 'iterating' || step === 'saving') && (
          <StepPreview
            html={this.state.html}
            markdown={this.state.markdown}
            loading={step === 'iterating' || step === 'saving'}
            onIterate={this.handleIterate}
            onSave={this.handleSave}
            onStartOver={this.handleStartOver}
            hasExistingPage={organization.has_page}
          />
        )}
      </div>
    );
  }
}
```

**Step 2: Create StepInput component**

Create `app/javascript/orgWizard/components/StepInput.jsx`:

```jsx
import { h, Component } from 'preact';

export class StepInput extends Component {
  constructor(props) {
    super(props);
    this.state = {
      urls: props.urls || [''],
    };
  }

  handleUrlChange = (index, value) => {
    const urls = [...this.state.urls];
    urls[index] = value;
    this.setState({ urls });
  };

  addUrl = () => {
    if (this.state.urls.length < 4) {
      this.setState({ urls: [...this.state.urls, ''] });
    }
  };

  removeUrl = (index) => {
    if (this.state.urls.length > 1) {
      const urls = this.state.urls.filter((_, i) => i !== index);
      this.setState({ urls });
    }
  };

  handleSubmit = (e) => {
    e.preventDefault();
    const validUrls = this.state.urls.filter((u) => u.trim());
    if (validUrls.length > 0) {
      this.props.onSubmit(validUrls);
    }
  };

  render() {
    const { loading } = this.props;
    const { urls } = this.state;

    if (loading) {
      return (
        <div className="text-center py-8">
          <div className="crayons-indicator crayons-indicator--loading" />
          <p className="fs-l mt-4 color-base-70">Learning about your organization...</p>
          <p className="fs-s color-base-60">Checking your site, searching DEV, detecting brand colors...</p>
        </div>
      );
    }

    return (
      <form onSubmit={this.handleSubmit}>
        <p className="color-base-70 mb-6">
          Share a link to your website or marketing page and we&apos;ll build you a beautiful org page
          using your content and what the DEV community has written about you.
        </p>

        {urls.map((url, index) => (
          <div key={index} className="flex items-center gap-2 mb-3">
            <input
              type="url"
              className="crayons-textfield flex-1"
              placeholder={index === 0 ? 'https://your-org.com' : 'https://docs.your-org.com (optional)'}
              value={url}
              required={index === 0}
              onInput={(e) => this.handleUrlChange(index, e.target.value)}
            />
            {index > 0 && (
              <button
                type="button"
                className="crayons-btn crayons-btn--ghost crayons-btn--icon"
                onClick={() => this.removeUrl(index)}
                aria-label="Remove URL"
              >
                &times;
              </button>
            )}
          </div>
        ))}

        {urls.length < 4 && (
          <button
            type="button"
            className="crayons-btn crayons-btn--ghost fs-s mb-4"
            onClick={this.addUrl}
          >
            + Add another link
          </button>
        )}

        <div className="mt-6">
          <button type="submit" className="crayons-btn">
            Let&apos;s go
          </button>
        </div>
      </form>
    );
  }
}
```

**Step 3: Commit**

```bash
git add app/javascript/orgWizard/OrgWizard.jsx app/javascript/orgWizard/components/StepInput.jsx
git commit -m "Add OrgWizard Preact component with Step 1 (URL input)"
```

---

### Task 8: Preact StepReview Component (Step 2)

**Files:**
- Create: `app/javascript/orgWizard/components/StepReview.jsx`

**Step 1: Create the component**

Create `app/javascript/orgWizard/components/StepReview.jsx`:

```jsx
import { h } from 'preact';

export function StepReview({
  crawlData,
  editedData,
  selectedPosts,
  loading,
  onEditData,
  onTogglePost,
  onGenerate,
  onBack,
}) {
  if (loading) {
    return (
      <div className="text-center py-8">
        <div className="crayons-indicator crayons-indicator--loading" />
        <p className="fs-l mt-4 color-base-70">Generating your page...</p>
        <p className="fs-s color-base-60">Our AI is crafting something beautiful using your content and DEV community posts.</p>
      </div>
    );
  }

  const devPosts = crawlData?.dev_posts || [];

  return (
    <div>
      <h2 className="fs-xl mb-4">Here&apos;s what we found</h2>

      <div className="mb-4">
        <label className="crayons-field__label" htmlFor="wizard-tagline">Tagline</label>
        <input
          id="wizard-tagline"
          className="crayons-textfield"
          value={editedData.title || ''}
          onInput={(e) => onEditData({ ...editedData, title: e.target.value })}
        />
      </div>

      <div className="mb-4">
        <label className="crayons-field__label" htmlFor="wizard-description">Description</label>
        <textarea
          id="wizard-description"
          className="crayons-textfield"
          rows={3}
          value={editedData.description || ''}
          onInput={(e) => onEditData({ ...editedData, description: e.target.value })}
        />
      </div>

      {editedData.detected_color && (
        <div className="mb-4">
          <label className="crayons-field__label" htmlFor="wizard-color">Brand Color</label>
          <div className="flex items-center gap-3">
            <div
              style={{
                width: '36px',
                height: '36px',
                borderRadius: '6px',
                backgroundColor: editedData.detected_color,
                border: '1px solid var(--base-30)',
              }}
            />
            <input
              id="wizard-color"
              type="color"
              value={editedData.detected_color}
              onChange={(e) => onEditData({ ...editedData, detected_color: e.target.value })}
              className="crayons-btn crayons-btn--ghost crayons-btn--s"
              style={{ width: '36px', height: '36px', padding: 0, cursor: 'pointer' }}
            />
            <span className="fs-s color-base-60">{editedData.detected_color}</span>
          </div>
        </div>
      )}

      {devPosts.length > 0 && (
        <div className="mb-6">
          <h3 className="fs-l mb-2">Popular on DEV</h3>
          <p className="fs-s color-base-60 mb-3">Select posts to feature on your page:</p>
          <ul className="list-none p-0">
            {devPosts.map((post) => (
              <li key={post.id} className="flex items-center gap-2 py-2 border-b border-base-10">
                <input
                  type="checkbox"
                  className="crayons-checkbox"
                  checked={selectedPosts.includes(post.id)}
                  onChange={() => onTogglePost(post.id)}
                  id={`post-${post.id}`}
                />
                <label htmlFor={`post-${post.id}`} className="flex-1 cursor-pointer">
                  <span className="fw-medium">{post.title}</span>
                  <span className="fs-s color-base-60 ml-2">
                    {post.reactions} reactions
                  </span>
                </label>
              </li>
            ))}
          </ul>
        </div>
      )}

      <div className="flex gap-2 mt-6">
        <button className="crayons-btn" onClick={onGenerate}>
          Generate My Page
        </button>
        <button className="crayons-btn crayons-btn--ghost" onClick={onBack}>
          Back
        </button>
      </div>
    </div>
  );
}
```

**Step 2: Commit**

```bash
git add app/javascript/orgWizard/components/StepReview.jsx
git commit -m "Add StepReview component for org wizard Step 2"
```

---

### Task 9: Preact StepPreview Component (Step 3 — Preview + Iteration)

**Files:**
- Create: `app/javascript/orgWizard/components/StepPreview.jsx`

**Step 1: Create the component**

Create `app/javascript/orgWizard/components/StepPreview.jsx`:

```jsx
import { h, Component } from 'preact';

export class StepPreview extends Component {
  constructor(props) {
    super(props);
    this.state = {
      feedback: '',
      showConfirmOverwrite: false,
    };
  }

  handleIterate = (e) => {
    e.preventDefault();
    const { feedback } = this.state;
    if (feedback.trim()) {
      this.props.onIterate(feedback.trim());
      this.setState({ feedback: '' });
    }
  };

  handleSave = () => {
    if (this.props.hasExistingPage) {
      this.setState({ showConfirmOverwrite: true });
    } else {
      this.props.onSave();
    }
  };

  confirmSave = () => {
    this.setState({ showConfirmOverwrite: false });
    this.props.onSave();
  };

  render() {
    const { html, loading, onStartOver } = this.props;
    const { feedback, showConfirmOverwrite } = this.state;

    return (
      <div>
        <h2 className="fs-xl mb-4">Your new page</h2>

        {/* Live preview */}
        <div className="crayons-card mb-4 p-4 overflow-auto" style={{ maxHeight: '600px' }}>
          {loading && (
            <div className="text-center py-4">
              <div className="crayons-indicator crayons-indicator--loading" />
              <p className="fs-s color-base-60 mt-2">Updating your page...</p>
            </div>
          )}
          <div
            className="crayons-article__body text-styles"
            dangerouslySetInnerHTML={{ __html: html }}
            style={{ opacity: loading ? 0.5 : 1 }}
          />
        </div>

        {/* Iteration prompt */}
        <form onSubmit={this.handleIterate} className="mb-4">
          <div className="flex gap-2">
            <input
              type="text"
              className="crayons-textfield flex-1"
              placeholder="Tell AI what to change..."
              value={feedback}
              onInput={(e) => this.setState({ feedback: e.target.value })}
              disabled={loading}
            />
            <button
              type="submit"
              className="crayons-btn crayons-btn--secondary"
              disabled={loading || !feedback.trim()}
            >
              Apply
            </button>
          </div>
        </form>

        {/* Overwrite confirmation */}
        {showConfirmOverwrite && (
          <div className="crayons-notice crayons-notice--warning mb-4">
            <p>Your org already has a page. This will replace it. Continue?</p>
            <div className="flex gap-2 mt-2">
              <button className="crayons-btn crayons-btn--s" onClick={this.confirmSave}>
                Yes, replace it
              </button>
              <button
                className="crayons-btn crayons-btn--ghost crayons-btn--s"
                onClick={() => this.setState({ showConfirmOverwrite: false })}
              >
                Cancel
              </button>
            </div>
          </div>
        )}

        {/* Actions */}
        <div className="flex gap-2">
          {!showConfirmOverwrite && (
            <button
              className="crayons-btn"
              onClick={this.handleSave}
              disabled={loading}
            >
              Looks good — Save Page
            </button>
          )}
          <button
            className="crayons-btn crayons-btn--ghost"
            onClick={onStartOver}
            disabled={loading}
          >
            Start Over
          </button>
        </div>
      </div>
    );
  }
}
```

**Step 2: Commit**

```bash
git add app/javascript/orgWizard/components/StepPreview.jsx
git commit -m "Add StepPreview component for org wizard Step 3 with iteration"
```

---

### Task 10: i18n Locales

**Files:**
- Modify: `config/locales/en.yml`
- Modify: `config/locales/fr.yml`
- Modify: `config/locales/pt.yml`

**Step 1: Add English locale strings**

Add under appropriate section in `config/locales/en.yml`:

```yaml
  org_wizard:
    page_title: "AI Page Wizard"
    crawl_failed: "We couldn't reach that URL. Please check it and try again."
    generate_failed: "Page generation failed. Please try again."
    save_success: "Your org page has been created!"
    save_failed: "Failed to save page. Please try again."
    unauthorized: "You must be an admin of this organization."
```

**Step 2: Add French locale strings**

Add to `config/locales/fr.yml`:

```yaml
  org_wizard:
    page_title: "Assistant de page IA"
    crawl_failed: "Nous n'avons pas pu atteindre cette URL. Veuillez la vérifier et réessayer."
    generate_failed: "La génération de la page a échoué. Veuillez réessayer."
    save_success: "Votre page d'organisation a été créée !"
    save_failed: "Échec de l'enregistrement de la page. Veuillez réessayer."
    unauthorized: "Vous devez être administrateur de cette organisation."
```

**Step 3: Add Portuguese locale strings**

Add to `config/locales/pt.yml`:

```yaml
  org_wizard:
    page_title: "Assistente de Página IA"
    crawl_failed: "Não conseguimos acessar essa URL. Verifique e tente novamente."
    generate_failed: "A geração da página falhou. Tente novamente."
    save_success: "Sua página da organização foi criada!"
    save_failed: "Falha ao salvar a página. Tente novamente."
    unauthorized: "Você deve ser um administrador desta organização."
```

**Step 4: Commit**

```bash
git add config/locales/en.yml config/locales/fr.yml config/locales/pt.yml
git commit -m "Add i18n locales for org page wizard (en, fr, pt)"
```

---

### Task 11: Entry Points — Settings Button + Post-Creation Redirect

**Files:**
- Modify: `app/views/organization_settings/edit.html.erb` (add "Generate Page with AI" button)
- Modify: `app/controllers/organizations_controller.rb` (or equivalent — add post-creation redirect)

**Step 1: Add button to org settings**

Find the page editor section in `app/views/organization_settings/edit.html.erb`. Add above the markdown editor textarea:

```erb
<% if !@organization.readme_page? && defined?(AI_AVAILABLE) && AI_AVAILABLE %>
  <div class="crayons-notice crayons-notice--info mb-4">
    <p class="fw-medium"><%= I18n.t("org_wizard.page_title") %></p>
    <p class="fs-s mb-2">Let AI generate a beautiful page for your organization using your website and DEV community content.</p>
    <%= link_to I18n.t("org_wizard.page_title"), org_wizard_path(@organization.slug),
        class: "crayons-btn crayons-btn--s" %>
  </div>
<% end %>
```

Also add a link for orgs that already have a page (to regenerate):

```erb
<% if @organization.readme_page? && defined?(AI_AVAILABLE) && AI_AVAILABLE %>
  <p class="fs-s color-base-60 mb-2">
    Want to start fresh? <%= link_to "Regenerate with AI", org_wizard_path(@organization.slug) %>
  </p>
<% end %>
```

**Step 2: Verify manually**

Visit an org settings page and confirm the button appears when AI is available and the org has no page.

**Step 3: Commit**

```bash
git add app/views/organization_settings/edit.html.erb
git commit -m "Add AI page wizard entry points in org settings"
```

---

### Task 12: Final Integration Test

**Files:**
- Modify: `spec/requests/org_wizard_spec.rb` (add full-flow integration test)

**Step 1: Add full-flow test**

Add to the existing spec file:

```ruby
describe "full flow: crawl → generate → save" do
  before do
    sign_in admin
    allow(HTTParty).to receive(:get).and_return(double(body: "<html><title>Test</title></html>"))
    mock_page = instance_double(MetaInspector,
                                best_title: "Test Org",
                                description: "A test org",
                                best_url: "https://test.com",
                                images: double(best: nil),
                                meta: {},
                                meta_tags: { "name" => {} })
    allow(MetaInspector).to receive(:new).and_return(mock_page)
    allow(Ai::Base).to receive(:new).and_return(double(call: "## Welcome\n\nHello from Test Org."))
  end

  it "generates and saves an org page end-to-end" do
    # Step 1: Crawl
    post "/org-wizard/#{organization.slug}/crawl", params: { urls: ["https://test.com"] }, as: :json
    expect(response).to have_http_status(:ok)
    crawl_data = response.parsed_body

    # Step 2: Generate
    post "/org-wizard/#{organization.slug}/generate",
         params: { org_data: { title: crawl_data["title"], description: crawl_data["description"] }, dev_posts: [] },
         as: :json
    expect(response).to have_http_status(:ok)
    gen_data = response.parsed_body
    expect(gen_data["markdown"]).to include("Welcome")

    # Step 3: Save
    post "/org-wizard/#{organization.slug}/save",
         params: { markdown: gen_data["markdown"], detected_color: "#FF0000" },
         as: :json
    expect(response).to have_http_status(:ok)

    organization.reload
    expect(organization.page_markdown).to include("Welcome")
    expect(organization.bg_color_hex).to eq("#FF0000")
  end
end
```

**Step 2: Run full test suite**

Run: `bundle exec rspec spec/requests/org_wizard_spec.rb`
Expected: ALL PASS

**Step 3: Run broader test suite to check for regressions**

Run: `bundle exec rspec spec/services/ai/ spec/requests/org_wizard_spec.rb`
Expected: ALL PASS

**Step 4: Commit**

```bash
git add spec/requests/org_wizard_spec.rb
git commit -m "Add full integration test for org page wizard flow"
```

---

## Task Summary

| Task | Component | Type |
|------|-----------|------|
| 1 | Ai::LiquidTagGuide module | Backend (extract + refactor) |
| 2 | Ai::OrgPageCrawler service | Backend (new service) |
| 3 | Ai::OrgPageGenerator service | Backend (new service) |
| 4 | Routes + OrgWizardController | Backend (controller) |
| 5 | Rails view (mount point) | View |
| 6 | Preact pack entry point | Frontend (wiring) |
| 7 | OrgWizard + StepInput component | Frontend (Step 1) |
| 8 | StepReview component | Frontend (Step 2) |
| 9 | StepPreview component | Frontend (Step 3) |
| 10 | i18n locales (en, fr, pt) | Config |
| 11 | Entry points in org settings | View (integration) |
| 12 | Full integration test | Test |

**Dependencies:** Tasks 1→3 (generator needs guide module). Tasks 2+3→4 (controller needs services). Tasks 4+5→6→7→8→9 (frontend chain). Task 10 is independent. Task 11 depends on 4 (routes). Task 12 depends on all backend tasks.

**Parallelizable:** Tasks 1, 2 can run in parallel. Tasks 7, 8, 9 can be developed independently. Task 10 can run anytime.
