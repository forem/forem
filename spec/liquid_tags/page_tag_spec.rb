require "rails_helper"

RSpec.describe PageTag, type: :liquid_tag do
  after do
    RequestStore.store[:subforem_id] = nil
  end

  describe "{% page ... %}" do
    it "renders an iframe with ?mode=embed for a /page/:slug page via URL, path, or bare slug", :aggregate_failures do
      create(:page, slug: "custom-landing", title: "Custom Landing", body_markdown: "Hello world")

      [
        "#{URL.url}/page/custom-landing",
        "/page/custom-landing",
        "custom-landing",
      ].each do |input|
        rendered = Liquid::Template.parse("{% page #{input} %}").render
        expect(rendered).to include('class="ltag__page"')
        expect(rendered).to include("src=\"#{URL.url}/page/custom-landing?mode=embed\"")
        expect(rendered).to include('title="Custom Landing"')
        expect(rendered).to include('height="600px"')
      end
    end

    it "renders an iframe for top-level and nested pages", :aggregate_failures do
      top_page = create(
        :page, slug: "showcase-hub", title: "Showcase Hub", is_top_level_path: true, body_markdown: "Top"
      )
      nested_page = create(
        :page, slug: "guides/onboarding", title: "Onboarding Guide", is_top_level_path: true, body_markdown: "Nested"
      )
      deep_page = create(
        :page, slug: "docs/sdk/quickstart", title: "SDK Quickstart", is_top_level_path: true, body_markdown: "Deep"
      )

      expect(Liquid::Template.parse("{% page /#{top_page.slug} %}").render)
        .to include("src=\"#{URL.url}/showcase-hub?mode=embed\"")
      expect(Liquid::Template.parse("{% page /#{nested_page.slug} %}").render)
        .to include("src=\"#{URL.url}/guides/onboarding?mode=embed\"")
      expect(Liquid::Template.parse("{% page /#{deep_page.slug} %}").render)
        .to include("src=\"#{URL.url}/docs/sdk/quickstart?mode=embed\"")
    end

    it "renders an iframe for static PagesController routes", :aggregate_failures do
      %w[/about /faq /terms /privacy /code-of-conduct /p/editor_guide].each do |static_path|
        rendered = Liquid::Template.parse("{% page #{static_path} %}").render
        expect(rendered).to include("src=\"#{URL.url}#{static_path}?mode=embed\"")
      end
    end

    it "renders a trusted unsandboxed iframe for an organization custom page when org_readme is enabled" do
      organization = create(:organization, slug: "acme-org")
      FeatureFlag.enable(:org_readme, FeatureFlag::Actor[organization])
      create(
        :page,
        organization: organization,
        slug: "acme-org/handbook",
        title: "Acme Handbook",
        template: "full_within_layout",
        body_markdown: "Handbook body",
      )

      rendered = Liquid::Template.parse("{% page /acme-org/p/handbook %}").render
      expect(rendered).to include("src=\"#{URL.url}/acme-org/p/handbook?mode=embed\"")
      expect(rendered).to include('title="Acme Handbook"')
      expect(rendered).not_to include("sandbox=")
      expect(rendered).not_to include("credentialless")
    ensure
      FeatureFlag.disable(:org_readme, FeatureFlag::Actor[organization]) if organization
    end

    it "renders a strictly sandboxed credentialless iframe for an organization embed_html page", :aggregate_failures do
      organization = create(:organization, slug: "sandbox-org")
      FeatureFlag.enable(:org_readme, FeatureFlag::Actor[organization])
      create(
        :page,
        organization: organization,
        slug: "sandbox-org/embed/calculator",
        title: "Sandboxed Calculator",
        template: "embed_html",
        body_markdown: nil,
        body_html: "<div><script>window.ok = 1</script></div>",
      )

      [
        "{% page /sandbox-org/embed/calculator %}",
        "{% page sandbox-org/embed/calculator %}",
        "{% embed #{URL.url}/sandbox-org/embed/calculator %}",
        "{% embed /sandbox-org/embed/calculator 450 %}",
        "{% embed /sandbox-org/embed/calculator 450 frameless %}",
      ].each do |markup|
        html = MarkdownProcessor::Parser.new(markup).finalize
        expect(html).to include("src=\"#{URL.url}/sandbox-org/embed/calculator?mode=embed\"")
        expect(html).to include("sandbox=\"#{PageTag::IFRAME_SANDBOX}\"")
        expect(html).not_to include("allow-same-origin")
        expect(html).not_to include("allowfullscreen")
        expect(html).to include("credentialless")
        expect(html).to include('referrerpolicy="no-referrer"')
      end

      frameless_html = MarkdownProcessor::Parser.new("{% embed /sandbox-org/embed/calculator 450 frameless %}").finalize
      expect(frameless_html).to include("style=\"#{PageTag::FRAMELESS_STYLE}\"")
      expect(frameless_html).to include('height="450px"')

      article_html = MarkdownProcessor::Parser.new("{% embed /sandbox-org/embed/calculator %}").finalize
      feed_html = ActionController::Base.helpers.sanitize(article_html, scrubber: FeedMarkdownScrubber.new)
      expect(feed_html).to include("sandbox=\"#{PageTag::IFRAME_SANDBOX}\"")
      expect(feed_html).to include("credentialless")
      expect(feed_html).to include('referrerpolicy="no-referrer"')
      expect(feed_html).to include("allow=\"#{PageTag::IFRAME_ALLOW_POLICY}\"")
    ensure
      FeatureFlag.disable(:org_readme, FeatureFlag::Actor[organization]) if organization
    end

    it "uses the subforem domain when embedding a subforem-scoped page" do
      subforem = create(:subforem, domain: "ai.example.com")
      page = create(:page, slug: "ai-rules", title: "AI Rules", subforem_id: subforem.id, body_markdown: "Rules")

      rendered = Liquid::Template.parse("{% page /page/#{page.slug} %}").render
      expect(rendered).to include("src=\"#{URL.page(page)}?mode=embed\"")
    end

    it "preserves URL fragments alongside ?mode=embed" do
      page = create(:page, slug: "faq-details", title: "FAQ Details", body_markdown: "Details")

      rendered = Liquid::Template.parse("{% page /page/#{page.slug}#pricing %}").render
      expect(rendered).to include("src=\"#{URL.url}/page/faq-details?mode=embed#pricing\"")
    end

    it "supports optional height and ratio arguments", :aggregate_failures do
      page = create(:page, slug: "sized-page", title: "Sized Page", body_markdown: "Body")

      expect(Liquid::Template.parse("{% page /page/#{page.slug} 450 %}").render).to include('height="450px"')
      expect(Liquid::Template.parse("{% page /page/#{page.slug} 480px %}").render).to include('height="480px"')
      expect(Liquid::Template.parse("{% page /page/#{page.slug} height=520 %}").render).to include('height="520px"')
      expect(Liquid::Template.parse("{% page /page/#{page.slug} landscape %}").render).to include('height="400px"')
      expect(Liquid::Template.parse("{% page /page/#{page.slug} portrait %}").render).to include('height="900px"')
      expect(Liquid::Template.parse("{% page /page/#{page.slug} 50 %}").render).to include('height="150px"')
      expect(Liquid::Template.parse("{% page /page/#{page.slug} 5000 %}").render).to include('height="2000px"')
    end

    it "keeps the frame by default and drops it with the frameless keyword", :aggregate_failures do
      page = create(:page, slug: "framed-page", title: "Framed Page", body_markdown: "Body")

      framed = Liquid::Template.parse("{% page /page/#{page.slug} 450 %}").render
      expect(framed).to include("style=\"#{described_class::FRAMED_STYLE}\"")

      [
        ["{% page /page/#{page.slug} 450 frameless %}", "450px"],
        ["{% page /page/#{page.slug} frameless 450 %}", "450px"],
        ["{% page /page/#{page.slug} frameless %}", described_class::DEFAULT_HEIGHT],
        ["{% page /page/#{page.slug} landscape FRAMELESS %}", described_class::LANDSCAPE_HEIGHT],
      ].each do |markup, height|
        rendered = Liquid::Template.parse(markup).render
        expect(rendered).to include("style=\"#{described_class::FRAMELESS_STYLE}\"")
        expect(rendered).to include("height=\"#{height}\"")
        expect(rendered).not_to include("var(--card-border")
      end
    end

    it "rejects non-HTML, redirect, feature-disabled, external, and missing pages", :aggregate_failures do
      json_page = create(
        :page, slug: "json-page", template: "json", body_json: '{"a":1}', body_markdown: nil, body_html: nil
      )
      redirect_page = create(:page, slug: "redirect-page", redirect_to_url: "/about")
      gated_page = create(:page, slug: "gated-page", body_markdown: "Secret")
      allow(FeatureFlag).to receive(:accessible?).and_call_original
      allow(FeatureFlag).to receive(:accessible?).with(gated_page.feature_flag_name).and_return(false)

      [
        "/page/#{json_page.slug}",
        "/page/#{redirect_page.slug}",
        "/page/#{gated_page.slug}",
        "https://example.com/about",
        "/does-not-exist-anywhere",
      ].each do |invalid_target|
        expect do
          Liquid::Template.parse("{% page #{invalid_target} %}")
        end.to raise_error(StandardError, I18n.t("liquid_tags.page_tag.invalid_page"))
      end
    end
  end

  describe "UnifiedEmbed ({% embed ... %}) page detection and fallback" do
    it "uses PageTag iframe when {% embed ... %} receives an on-site page URL or path", :aggregate_failures do
      page = create(:page, slug: "interactive-demo", title: "Interactive Demo", body_markdown: "Demo")
      top_page = create(:page, slug: "live-hub", title: "Live Hub", is_top_level_path: true, body_markdown: "Hub")

      [
        ["#{URL.url}/page/#{page.slug}", "#{URL.url}/page/interactive-demo?mode=embed", "600px"],
        ["/page/#{page.slug} landscape", "#{URL.url}/page/interactive-demo?mode=embed", "400px"],
        ["#{URL.url}/#{top_page.slug}", "#{URL.url}/live-hub?mode=embed", "600px"],
        ["/#{top_page.slug}", "#{URL.url}/live-hub?mode=embed", "600px"],
        ["#{URL.url}/about", "#{URL.url}/about?mode=embed", "600px"],
        ["/about", "#{URL.url}/about?mode=embed", "600px"],
      ].each do |embed_arg, expected_src, expected_height|
        parsed = MarkdownProcessor::Parser.new("{% embed #{embed_arg} %}")
        html = parsed.finalize
        expect(html).to include("ltag__page")
        expect(html).to include("src=\"#{expected_src}\"")
        expect(html).to include("height=\"#{expected_height}\"")
      end
    end

    it "falls back to LinkTag when URL or path points to an Article rather than a Page", :aggregate_failures do
      author = create(:user, username: "articleauthor")
      article = create(:article, user: author, title: "Fallback Article")

      [
        "#{URL.url}#{article.path}",
        article.path,
      ].each do |target|
        expect(UnifiedEmbed::Registry.find_liquid_tag_for(link: target)).to eq(LinkTag)
        rendered = Liquid::Template.parse("{% embed #{target} %}").render
        expect(rendered).to include("ltag__link")
        expect(rendered).not_to include("ltag__page")
      end
    end

    it "falls back to UserTag, OrganizationTag, and TagTag for non-page on-site paths and URLs", :aggregate_failures do
      user = create(:user, username: "fallbackuser")
      org = create(:organization, slug: "fallbackorg")
      tag = create(:tag, name: "fallbacktag")
      org_url = "#{URL.url}/#{org.slug}"
      allow(UnifiedEmbed::Tag).to receive(:validate_link).with(input: org_url).and_return(org_url)

      expect(Liquid::Template.parse("{% embed /#{user.username} %}").render).to include("ltag__user")
      expect(Liquid::Template.parse("{% embed #{org_url} %}").render).to include(org.name)
      expect(Liquid::Template.parse("{% embed /t/#{tag.name} %}").render).to include("ltag__tag")
      expect(ForemTag.determine_klass("#{URL.url}/about")).to eq(described_class)
    end
  end

  describe "user embed_html pages and article-only attribution footer" do
    before do
      FeatureFlag.add(:user_embed_pages)
    end

    it "renders a sandboxed iframe for a user embed_html page when flag is enabled", :aggregate_failures do
      embed_owner = create(:user, username: "devwidgetauthor", name: "Widget Author")
      FeatureFlag.enable(:user_embed_pages, FeatureFlag::Actor[embed_owner])
      create(
        :page,
        user: embed_owner,
        slug: "#{embed_owner.username}/embed/live-chart",
        title: "Live Chart",
        description: "Chart widget",
        template: "embed_html",
        body_markdown: nil,
        body_html: "<div>Chart</div>",
      )

      rendered = MarkdownProcessor::Parser.new("{% embed /#{embed_owner.username}/embed/live-chart 420 %}").finalize
      expect(rendered).to include("src=\"#{URL.url}/#{embed_owner.username}/embed/live-chart?mode=embed\"")
      expect(rendered).to include("sandbox=\"#{PageTag::IFRAME_SANDBOX}\"")
      expect(rendered).not_to include("allow-same-origin")
      expect(rendered).not_to include("allowfullscreen")
      expect(rendered).to include("credentialless")
      expect(rendered).to include('referrerpolicy="no-referrer"')
      expect(rendered).to include('height="420px"')
    ensure
      FeatureFlag.disable(:user_embed_pages, FeatureFlag::Actor[embed_owner]) if embed_owner
    end

    it "rejects user embed_html pages when feature flag is disabled or owner is suspended", :aggregate_failures do
      embed_owner = create(:user, username: "gatedwidgetuser")
      create(
        :page,
        user: embed_owner,
        slug: "#{embed_owner.username}/embed/secret-chart",
        title: "Secret Chart",
        description: "desc",
        template: "embed_html",
        body_markdown: nil,
        body_html: "<div>Chart</div>",
      )

      expect do
        Liquid::Template.parse("{% page /#{embed_owner.username}/embed/secret-chart %}")
      end.to raise_error(StandardError, I18n.t("liquid_tags.page_tag.invalid_page"))

      FeatureFlag.enable(:user_embed_pages, FeatureFlag::Actor[embed_owner])
      embed_owner.add_role(:suspended)

      expect do
        Liquid::Template.parse("{% page /#{embed_owner.username}/embed/secret-chart %}")
      end.to raise_error(StandardError, I18n.t("liquid_tags.page_tag.invalid_page"))
    ensure
      FeatureFlag.disable(:user_embed_pages, FeatureFlag::Actor[embed_owner]) if embed_owner
    end

    it "renders the attribution bar and fullscreen button only in articles", :aggregate_failures do
      embed_owner = create(:user, username: "barowner", name: "Bar Owner")
      article_author = create(:user, username: "postwriter")
      article = build(:article, user: article_author)
      comment = build(:comment, user: article_author)
      org = create(:organization, slug: "bar-org", name: "Bar Org")

      FeatureFlag.enable(:user_embed_pages, FeatureFlag::Actor[embed_owner])
      FeatureFlag.enable(:org_readme, FeatureFlag::Actor[org])

      create(
        :page,
        user: embed_owner,
        slug: "#{embed_owner.username}/embed/interactive-card",
        title: "Interactive Card",
        description: "desc",
        template: "embed_html",
        body_markdown: nil,
        body_html: "<div>Card</div>",
      )
      create(
        :page,
        organization: org,
        slug: "#{org.slug}/docs",
        title: "Org Docs",
        description: "desc",
        template: "full_within_layout",
        body_markdown: "Docs body",
      )

      user_article_html = ContentRenderer.new(
        "{% embed /#{embed_owner.username}/embed/interactive-card %}",
        source: article,
        user: article_author,
      ).process_article.processed_html

      expect(user_article_html).to include("ltag__page--article")
      expect(user_article_html).to include("js-page-embed")
      expect(user_article_html).to include("ltag__page-footer")
      expect(user_article_html).to include("js-fullscreen-page-action")
      expect(user_article_html).to include("Interactive Card")
      expect(user_article_html).to include("Bar Owner")
      expect(user_article_html).to include("href=\"#{embed_owner.path}\"")
      expect(user_article_html).to include('data-ignore-prefix="true"')
      expect(user_article_html).not_to include("article-body-image-wrapper")
      expect(user_article_html).not_to include("<pre><code>")

      org_article_html = ContentRenderer.new(
        "{% embed /#{org.slug}/p/docs %}",
        source: article,
        user: article_author,
      ).process_article.processed_html

      expect(org_article_html).to include("ltag__page-footer")
      expect(org_article_html).to include("Bar Org")
      expect(org_article_html).to include("href=\"/#{org.slug}/p/docs\"")
      expect(org_article_html).to include("js-fullscreen-page-action")

      site_article_html = ContentRenderer.new(
        "{% embed /about %}",
        source: article,
        user: article_author,
      ).process_article.processed_html

      expect(site_article_html).to include("ltag__page-footer")
      expect(site_article_html).to include('href="/about"')
      expect(site_article_html).to include("js-fullscreen-page-action")

      feed_html = ActionController::Base.helpers.sanitize(user_article_html, scrubber: FeedMarkdownScrubber.new)
      expect(feed_html).to include("Interactive Card")
      expect(feed_html).to include("Bar Owner")
      expect(feed_html).not_to include(I18n.t("services.html.parser.enter_fullscreen_mode"))

      in_page_html = ContentRenderer.new(
        "{% embed /#{embed_owner.username}/embed/interactive-card %}",
        source: org,
      ).process.processed_html
      expect(in_page_html).not_to include("ltag__page-footer")
      expect(in_page_html).not_to include("js-fullscreen-page-action")

      in_comment_html = ContentRenderer.new(
        "{% embed /about %}",
        source: comment,
        user: article_author,
      ).process.processed_html
      expect(in_comment_html).not_to include("ltag__page-footer")
      expect(in_comment_html).not_to include("js-fullscreen-page-action")
    ensure
      FeatureFlag.disable(:user_embed_pages, FeatureFlag::Actor[embed_owner]) if embed_owner
      FeatureFlag.disable(:org_readme, FeatureFlag::Actor[org]) if org
    end
  end
end
