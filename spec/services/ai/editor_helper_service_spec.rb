require "rails_helper"

RSpec.describe Ai::EditorHelperService do
  let(:user) { create(:user) }
  let(:service) { described_class.new(user) }

  describe "#prompt" do
    before do
      # Disable caching so we can consistently test the final prompt string rendering dynamically
      allow(Rails.cache).to receive(:fetch).and_yield

      # Mock the dependent views natively wrapped by ActionView
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(/_editor_guide_text.en.html.erb/).and_return("Clean editor guide mocked.")
      allow(File).to receive(:read).with(/_supported_url_embeds_list.en.html.erb/).and_return("Clean url embed mocked.")
      allow(File).to receive(:read)
        .with(/_supported_nonurl_embeds_list.en.html.erb/)
        .and_return("Clean block embed mocked.")
    end

    it "embeds the hardcoded platform mechanics natively" do
      prompt = service.__send__(:prompt)
      community = Settings::Community.community_name

      expect(prompt).to include("insightful technical editor assistant for the #{community} community")
      expect(prompt).to include("Platform Mechanics Overview:")
      expect(prompt).to include("Editor Versions & Formatting Toolbar:")
      expect(prompt).to include("Basic Markdown (v1) Front Matter Fields:")
      expect(prompt).to include("Tags are the primary organizational mechanism on the platform.")
      expect(prompt).to include("Catchy, plain-language titles historically perform better.")
      expect(prompt).to include("Forem utilizes a heavily personalized algorithm")
    end

    it "includes comprehensive editor modes, UI controls, Liquid tags, and troubleshooting references" do
      prompt = service.__send__(:prompt)

      expect(prompt).to include("Editor Modes & Interface Reference:")
      expect(prompt).to include("Rich + Markdown Editor (`v2`, default)")
      expect(prompt).to include("Basic Markdown Editor (`v1`)")
      expect(prompt).to include("Markdown, HTML & Liquid Embed Reference:")
      expect(prompt).to include("Validation Rules & Common Error Troubleshooting:")
    end

    it "preserves ERB section headings, code blocks, and FeatureTag::ICONS when parsing real guide partials" do
      allow(File).to receive(:read).with(/_editor_guide_text.en.html.erb/).and_call_original
      allow(File).to receive(:read).with(/_supported_nonurl_embeds_list.en.html.erb/).and_call_original

      prompt = service.__send__(:prompt)

      expect(prompt).to include("### Bold & Italic")
      expect(prompt).to include("### Links")
      expect(prompt).to include("`<a name=\"chapter-1\"></a>`")
      expect(prompt).to include("Supported icons: `analytics`, `badge`")
      expect(prompt).not_to include(".permalink-heading svg")
    end

    it "enforces constraints against unsolicited advice in the guidelines" do
      prompt = service.__send__(:prompt)

      expect(prompt).to include(
        "NEVER give unsolicited advice on what subjects to write about " \
        "or how to structure the story itself UNLESS the user explicitly asks",
      )
    end

    it "does not render the advisement context block when advisement spec has no value" do
      allow(Settings::RateLimit).to receive(:expanded_content_advisement_spec).and_return(nil)

      prompt = service.__send__(:prompt)
      expect(prompt).not_to include("The platform explicitly specifies the following about ideal content")
    end

    it "embeds the configured advisement specs actively inside the prompt pipeline" do
      allow(Settings::RateLimit)
        .to receive(:expanded_content_advisement_spec)
        .and_return("Focus on deep technical blocks.")

      prompt = service.__send__(:prompt)

      expect(prompt).to include("The platform explicitly specifies the following about ideal content:")
      expect(prompt).to include("Focus on deep technical blocks.")
    end

    it "normalizes string-keyed and symbol-keyed history entries safely" do
      mixed_history = [
        { "role" => "user", "text" => "How do I add a cover video?" },
        { role: "assistant", text: "Use the Add a cover video option at the top." },
        nil,
        {},
      ]
      custom_service = described_class.new(user, history: mixed_history)

      prompt = custom_service.__send__(:prompt)

      expect(prompt).to include("User: How do I add a cover video?")
      expect(prompt).to include("Assistant: Use the Add a cover video option at the top.")
    end

    it "includes rich article metadata and reports a clean draft when no issues exist" do
      clean_body = <<~MARKDOWN
        ## Introduction

        Here is a clean paragraph with an image:

        ![Architecture diagram of worker queues](https://example.com/diagram.png)

        ```ruby
        puts 'hello'
        ```
      MARKDOWN

      article_state = {
        "title" => "Building Resilient Background Workers in Ruby",
        "tags" => "ruby, sidekiq, backend",
        "version" => "v2",
        "preview_showing" => true,
        "series" => "Production Ruby",
        "canonical_url" => "https://example.com/resilient-workers",
        "ai_disclosure_level" => "some_ai",
        "body" => clean_body
      }

      custom_service = described_class.new(user, article_state: article_state)
      prompt = custom_service.__send__(:prompt)

      expect(prompt).to include("Title: Building Resilient Background Workers in Ruby")
      expect(prompt).to include("Editor Version: v2 (Rich + Markdown UI)")
      expect(prompt).to include("Active Editor Tab: Preview")
      expect(prompt).to include("Tags: ruby, sidekiq, backend")
      expect(prompt).to include("Canonical URL: https://example.com/resilient-workers")
      expect(prompt).to include("Series: Production Ruby")
      expect(prompt).to include("AI Disclosure Level: some_ai")
      expect(prompt).to include("No syntax, validation, or accessibility errors detected in the current draft.")
    end

    it "surfaces active client UI errors and preview accessibility lint warnings" do
      article_state = {
        title: "My Draft",
        body: "## Section\n\nContent",
        errors: { errors: ["Title has already been taken", "Canonical URL is invalid"] },
        markdown_lint_errors: [
          {
            lineNumber: 4,
            ruleDescription: "Image alternate text should be descriptive",
            errorDetail: "Found default alt text"
          },
        ]
      }

      custom_service = described_class.new(user, article_state: article_state)
      prompt = custom_service.__send__(:prompt)

      expect(prompt).to include("[Active UI Error Banner] Title has already been taken")
      expect(prompt).to include("[Active UI Error Banner] Canonical URL is invalid")
      expect(prompt).to include(
        "[Preview Accessibility Notice - Line 4] Image alternate text should be descriptive Found default alt text",
      )
    end

    it "diagnoses blank or overly long titles and invalid tags" do
      article_state = {
        title: "",
        tags: "react-native, c++, validtag, fourth, fifth",
        body: "## Hello\n\nWorld"
      }

      custom_service = described_class.new(user, article_state: article_state)
      prompt = custom_service.__send__(:prompt)

      expect(prompt).to include("[Validation Warning] Title is blank.")
      expect(prompt).to include("[Tag Validation Error] 5 tags are selected")
      expect(prompt).to include("Tag `react-native` contains invalid characters")
      expect(prompt).to include("Use `reactnative` instead.")
      expect(prompt).to include("Tag `c++` contains invalid characters")
    end

    it "surfaces tag aliases and moderation instructions for selected tags" do
      create(:tag, name: "javascript")
      create(:tag, name: "js", alias_for: "javascript")
      create(
        :tag,
        name: "discuss",
        moderation_instructions: "Prompts should encourage open-ended community discussion.",
      )

      article_state = {
        title: "Let's talk about closures",
        tags: "js, discuss",
        body: "## Closures\n\nWhat do you think?"
      }

      custom_service = described_class.new(user, article_state: article_state)
      prompt = custom_service.__send__(:prompt)

      expect(prompt).to include("[Tag Note] Tag `#js` is an alias and will automatically resolve to `#javascript`.")
      expect(prompt).to include(
        "[Tag Guideline for #discuss] Prompts should encourage open-ended community discussion.",
      )
    end

    it "diagnoses frontmatter misuse in v2 mode and unrecognized frontmatter keys" do
      article_state = {
        title: "Frontmatter Test",
        version: "v2",
        body: <<~MARKDOWN
          ---
          title: "My Post"
          image: https://example.com/banner.png
          draft: true
          ---
          ## Content
        MARKDOWN
      }

      custom_service = described_class.new(user, article_state: article_state)
      prompt = custom_service.__send__(:prompt)

      expect(prompt).to include(
        "[Editor Mode Warning] YAML frontmatter (`--- ... ---`) was detected inside the post body",
      )
      expect(prompt).to include("Unrecognized frontmatter key `image:`. Did you mean `cover_image`?")
      expect(prompt).to include(
        "Unrecognized frontmatter key `draft:`. Did you mean `published (use `published: false` for drafts)`?",
      )
    end

    it "diagnoses malformed YAML frontmatter in v1 mode while extracting fallback keys" do
      article_state = {
        title: "",
        version: "v1",
        body: <<~MARKDOWN
          ---
          title: Why "Quotes" Break: Unquoted YAML
          published: false
          ---
          ## Body
        MARKDOWN
      }

      custom_service = described_class.new(user, article_state: article_state)
      prompt = custom_service.__send__(:prompt)

      expect(prompt).to include("[Frontmatter YAML Syntax Error]")
      expect(prompt).not_to include("[Validation Warning] Title is blank.")
    end

    it "diagnoses Liquid tag errors including unclosed blocks, unknown tags, and invalid arguments" do
      article_state = {
        title: "Liquid Troubleshooting",
        body: <<~MARKDOWN
          ## Testing Liquid
          {{ user.name }}
          {% unknown_widget 123 %}
          {% embed not-a-url %}
          {% feed limit=99 %}
          {% slide image="https://example.com/a.png" %}
          {% endembed %}
          {% card %}
          Unclosed card content
        MARKDOWN
      }

      custom_service = described_class.new(user, article_state: article_state)
      prompt = custom_service.__send__(:prompt)

      expect(prompt).to include("Unescaped Liquid variable expression `{{ user.name }}`")
      expect(prompt).to include("Unknown Liquid tag `{% unknown_widget %}`")
      expect(prompt).to include("`{% embed not-a-url %}` requires a full `http://` or `https://` URL.")
      expect(prompt).to include("`{% feed %}` requires at least one filter attribute")
      expect(prompt).to include("`{% feed %}` `limit` must be between 1 and 30 (got `99`).")
      expect(prompt).to include("`{% slide %}` must be placed inside a `{% slides %}...{% endslides %}` block.")
      expect(prompt).to include("`{% endembed %}` is invalid because `{% embed %}` is a single self-closing tag")
      expect(prompt).to include("Unclosed `{% card %}` block tag (missing matching `{% endcard %}`)")
    end

    it "diagnoses invalid attributes on feature, quote, slides, and slide Liquid tags" do
      article_state = {
        title: "Block Tag Attributes",
        body: <<~MARKDOWN
          {% feature icon="rocket" %}Missing title{% endfeature %}
          {% feature title="Custom" icon="nonexistent-icon-slug" %}Invalid icon{% endfeature %}
          {% quote author="Dev" rating=9 %}Invalid rating{% endquote %}
          {% slides mode="grid" %}
          {% slide title="Missing media" %}
          {% endslides %}
        MARKDOWN
      }

      custom_service = described_class.new(user, article_state: article_state)
      prompt = custom_service.__send__(:prompt)

      expect(prompt).to include("`{% feature %}` requires a `title=\"...\"` attribute")
      expect(prompt).to include("`{% feature %}` has unsupported `icon=\"nonexistent-icon-slug\"`")
      expect(prompt).to include("`{% quote %}` `rating` must be between 1 and 5 (got `9`).")
      expect(prompt).to include("`{% slides %}` `mode` must be `default` or `carousel` (got `grid`).")
      expect(prompt).to include("`{% slide %}` requires at least one of `image=\"https://...\"`")
    end

    it "ignores Liquid tags inside fenced code blocks, inline code, and raw blocks" do
      article_state = {
        title: "Tutorial on Liquid and Vue",
        body: <<~MARKDOWN
          ## Code Examples
          Inline `{{ vue_var }}` and `{% unknown_inline %}` are safe.
          {% raw %}{{ raw_var }} {% unknown_raw %}{% endraw %}
          ```html
          <div>{{ template_var }}</div>
          {% unknown_block_tag %}
          ```
        MARKDOWN
      }

      custom_service = described_class.new(user, article_state: article_state)
      prompt = custom_service.__send__(:prompt)

      expect(prompt).to include("No syntax, validation, or accessibility errors detected in the current draft.")
    end

    it "diagnoses Markdown syntax and accessibility issues with accurate line numbers" do
      article_state = {
        title: "Accessibility & Markdown Check",
        body: <<~MARKDOWN
          # Top Heading Should Be H2
          #### Skipped H3 Heading
          ![Image description](https://example.com/pic.png)
          ![](https://example.com/empty.png)
          [Broken link] (https://example.com)
          (Reversed link)[https://example.com]
          ```
          unclosed code fence without language
        MARKDOWN
      }

      custom_service = described_class.new(user, article_state: article_state)
      prompt = custom_service.__send__(:prompt)

      expect(prompt).to include("[Accessibility Warning - Line 1] Level 1 heading (`# `) used in the body.")
      expect(prompt).to include("[Accessibility Warning - Line 2] Heading level jumped from `<h1>` to `<h4>`")
      expect(prompt).to include(
        "[Accessibility Warning - Line 3] Image uses the default `![Image description](...)` placeholder",
      )
      expect(prompt).to include("[Accessibility Warning - Line 4] Image has empty alt text `![](...)`")
      expect(prompt).to include("[Markdown Syntax Warning - Line 5] Space detected between `]` and `(`")
      expect(prompt).to include("[Markdown Syntax Warning - Line 6] Reversed link syntax `(text)[url]`")
      expect(prompt).to include("[Markdown Syntax Error - Line 7] Unclosed fenced code block")
      expect(prompt).to include("[Formatting Tip - Line 7] Fenced code block (` ``` `) has no language identifier")
    end

    it "warns when an unindented image inside a numbered list would reset list numbering" do
      article_state = {
        title: "Numbered List Check",
        body: <<~MARKDOWN
          ## Steps
          1. First step
          ![Step one diagram](https://example.com/step1.png)
          2. Second step
        MARKDOWN
      }

      custom_service = described_class.new(user, article_state: article_state)
      prompt = custom_service.__send__(:prompt)

      expect(prompt).to include("[Formatting Tip - Line 3] Unindented image inside a numbered list")
    end

    it "diagnoses invalid cover video URLs, duplicate canonical URLs, and blocked data URIs" do
      existing = create(:article, published: true)
      existing.update_column(:canonical_url, "https://example.com/taken-post")

      article_state = {
        title: "Metadata Checks",
        canonical_url: "https://example.com/taken-post",
        video_source_url: "https://vimeo.com/123456",
        body: "## Image\n\n<img src=\"data:image/png;base64,iVBORw0KGgo=\">"
      }

      custom_service = described_class.new(user, article_state: article_state)
      prompt = custom_service.__send__(:prompt)

      expect(prompt).to include("Canonical URL `https://example.com/taken-post` has already been taken")
      expect(prompt).to include("Cover video URL `https://vimeo.com/123456` is not from a supported provider")
      expect(prompt).to include("[Security Validation Error] Body contains a `data:` URI")
    end
  end
end
