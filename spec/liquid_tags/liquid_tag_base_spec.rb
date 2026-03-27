require "rails_helper"

RSpec.describe LiquidTagBase, type: :liquid_tag do
  # #new and #initialize are both private methods in Liquid::Tag, which is what
  # LiquidTagBase inherits from, so we treat this class as a liquid tag itself.
  before { Liquid::Template.register_tag("liquid_tag_base", described_class) }

  context "when context includes a policy" do
    let(:policy_klass) do
      Class.new(ApplicationPolicy) do
        def initialize?
          false
        end
      end
    end

    it "is used by Pundit for authorization" do
      source = create(:article)
      expect do
        liquid_tag_options = { source: source, user: source.user, policy: policy_klass }
        Liquid::Template.parse("{% liquid_tag_base %}", liquid_tag_options)
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context "when VALID_CONTEXTS are defined" do
    before { stub_const("#{described_class}::VALID_CONTEXTS", %w[Article]) }

    it "raises an error for invalid contexts" do
      source = create(:comment)
      expect do
        liquid_tag_options = { source: source, user: source.user }
        Liquid::Template.parse("{% liquid_tag_base %}", liquid_tag_options)
      end.to raise_error(LiquidTags::Errors::InvalidParseContext)
    end

    it "doesn't raise an error for valid contexts" do
      source = create(:article)
      expect do
        liquid_tag_options = { source: source, user: source.user }
        Liquid::Template.parse("{% liquid_tag_base %}", liquid_tag_options)
      end.not_to raise_error
    end
  end

  context "when VALID_CONTEXTS aren't defined" do
    it "does not validate contexts" do
      source = create(:article)
      liquid_tag_options = { source: source, user: source.user }
      expect do
        Liquid::Template.parse("{% liquid_tag_base %}", liquid_tag_options)
      end.not_to raise_error
    end
  end

  context "when .user_authorization_method_name is not nil" do
    it "raises an error for invalid roles" do
      source = create(:article)
      liquid_tag_options = { source: source, user: source.user }
      allow(described_class).to receive(:user_authorization_method_name).and_return(:admin?)
      expect do
        Liquid::Template.parse("{% liquid_tag_base %}", liquid_tag_options)
      end.to raise_error(Pundit::NotAuthorizedError)
    end

    it "doesn't raise an error for valid roles" do
      author = create(:user, :admin)
      source = create(:article, user: author)
      liquid_tag_options = { source: source, user: source.user }
      allow(described_class).to receive(:user_authorization_method_name).and_return(:admin?)
      expect do
        Liquid::Template.parse("{% liquid_tag_base %}", liquid_tag_options)
      end.not_to raise_error
    end
  end

  context "when .user_authorization_method_name is nil" do
    it "doesn't validate roles" do
      source = create(:article)
      liquid_tag_options = { source: source, user: source.user }
      allow(described_class).to receive(:user_authorization_method_name).and_return(nil)
      expect do
        Liquid::Template.parse("{% liquid_tag_base %}", liquid_tag_options)
      end.not_to raise_error
    end
  end

  describe "#render_to_output_buffer" do
    let(:user) { create(:user) }
    
    def parse_and_render(markdown)
      source = create(:article)
      template = Liquid::Template.parse(markdown, {source: source, user: user})
      template.render
    end

    it "wraps standard liquid tags with FOREM_LTAG HTML bounds" do
      result = parse_and_render("{% youtube dQw4w9WgXcQ %}")
      expect(result).to include("<!-- FOREM_LTAG_START: youtube dQw4w9WgXcQ -->")
      expect(result).to include("<!-- FOREM_LTAG_END: youtube dQw4w9WgXcQ -->")
    end

    it "handles malicious XSS string injections via CGI escaping to protect the comment block boundaries natively" do
      # Test the strict AST buffer injection isolation on an explicit XSS tag string 
      # to ensure HTML boundaries are not cleanly broken terminating the comment early.
      stub_tag_class = Class.new(LiquidTagBase) do
        def self.name; "XssTag"; end
        def initialize(_tag_name, input, _parse_context)
          @id = input.strip
        end
        def render(_context); "dummy"; end
      end

      dummy_tag = stub_tag_class.send(:new, "xss", "\"><script>alert(1)</script>", Liquid::ParseContext.new)
      output = String.new
      dummy_tag.render_to_output_buffer(Liquid::Context.new, output)

      expect(output).to include("<!-- FOREM_LTAG_START: xss &quot;&gt;&lt;script&gt;alert(1)&lt;/script&gt; -->")
      expect(output).to include("<!-- FOREM_LTAG_END: xss &quot;&gt;&lt;script&gt;alert(1)&lt;/script&gt; -->")
    end

    it "safely wraps valid UnifiedEmbed alias inputs identically" do
      result = parse_and_render("{% embed https://youtube.com/watch?v=dQw4w9WgXcQ %}")
      expect(result).to include("<!-- FOREM_LTAG_START: youtube dQw4w9WgXcQ -->")
    end
    
    it "handles Forem database Tag objects seamlessly" do
      create(:tag, name: "ruby")
      result = parse_and_render("{% tag ruby %}")
      expect(result).to include("<!-- FOREM_LTAG_START: tag ruby -->")
    end

    it "safely wraps valid DEV Article embeds leveraging UnifiedEmbed link mappings" do
      dev_article = create(:article, title: "Test Article")
      dev_article.user.update!(username: "testuser")
      
      domain = Settings::General.app_domain || "localhost:3000"
      article_url = "http://#{domain}/testuser/#{dev_article.slug}"

      stub_request(:head, article_url).to_return(status: 200, body: "", headers: {})
      stub_request(:get, article_url).to_return(status: 200, body: "<html><head></head><body>Example</body></html>", headers: {})

      result = parse_and_render("{% embed #{article_url} %}")
      expect(result).to include("<!-- FOREM_LTAG_START: link #{article_url} -->")
    end

    it "safely wraps direct platform Comment tags dynamically" do
      target_comment = create(:comment)
      result = parse_and_render("{% comment #{target_comment.id_code} %}")
      expect(result).to include("<!-- FOREM_LTAG_START: comment #{target_comment.id_code} -->")
    end

    it "safely wraps OpenGraph generic fallback URL embeds properly" do
      stub_request(:head, "https://example.com/unsupported-embed").to_return(status: 200, body: "", headers: {})
      stub_request(:get, "https://example.com/unsupported-embed").to_return(status: 200, body: "<html><head></head><body>Example</body></html>", headers: {})

      result = parse_and_render("{% embed https://example.com/unsupported-embed %}")
      expect(result).to include("<!-- FOREM_LTAG_START: open_graph https://example.com/unsupported-embed -->")
    end
  end
end
