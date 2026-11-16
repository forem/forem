require "rails_helper"

RSpec.describe Pages::EmbedHtmlWrapper do
  describe ".call" do
    it "wraps HTML fragments in a hardened standards-mode document with prelude script first", :aggregate_failures do
      wrapped = described_class.call(
        "<div id='demo'>Hello</div><script>window.demo = 1;</script>",
        blocked_hosts: ["dev.to"],
        local_http: false,
      )

      expect(wrapped).to start_with("<!DOCTYPE html>")
      expect(wrapped).to include('<html data-forem-embed="1" data-forem-theme="light">')
      expect(wrapped).to include('<meta name="referrer" content="no-referrer" data-forem-wrapper-meta="1">')
      expect(wrapped).to include('<meta http-equiv="Content-Security-Policy"')
      expect(wrapped).to include("frame-src 'none'")
      expect(wrapped).to include("worker-src 'none'")
      expect(wrapped).to include("form-action 'none'")
      expect(wrapped).to include('data-forem-wrapper-style="1"')
      expect(wrapped).to include('data-forem-wrapper-script="1"')
      expect(wrapped).to include('<div id="demo">Hello</div>')
      expect(wrapped).to include("<script>window.demo = 1;</script>")

      wrapper_idx = wrapped.index("data-forem-wrapper-script")
      user_script_idx = wrapped.index("window.demo = 1")
      expect(wrapper_idx).to be < user_script_idx
    end

    it "preserves full document structure and head assets after wrapper controls", :aggregate_failures do
      input = <<~HTML
        <!DOCTYPE html>
        <html lang="fr">
          <head>
            <title>Widget</title>
            <style>body > p { color: navy; }</style>
          </head>
          <body class="custom-body" data-widget="yes">
            <p>Content &amp; details</p>
            <script>const ok = 1 < 2 && true;</script>
          </body>
        </html>
      HTML

      wrapped = described_class.call(input, blocked_hosts: ["dev.to"], local_http: false)

      expect(wrapped.scan("<!DOCTYPE html>").size).to eq(1)
      expect(wrapped).to include('lang="fr"')
      expect(wrapped).to include('class="custom-body"')
      expect(wrapped).to include('data-widget="yes"')
      expect(wrapped).to include("<title>Widget</title>")
      expect(wrapped).to include("<style>body > p { color: navy; }</style>")
      expect(wrapped).to include("const ok = 1 < 2 && true;")

      expect(wrapped.index("data-forem-wrapper-script")).to be < wrapped.index("<title>Widget</title>")
    end

    it "strips dangerous elements, meta overrides, prefetch links, autofocus, ping, autoplay, and unsafe URIs",
       :aggregate_failures do
      input = <<~HTML
        <base href="https://evil.test/">
        <meta http-equiv="refresh" content="0;url=https://evil.test/">
        <meta http-equiv="Content-Security-Policy" content="script-src *">
        <meta name="referrer" content="unsafe-url">
        <link rel="dns-prefetch" href="https://tracker.test">
        <link rel="stylesheet" href="https://cdn.example.test/style.css">
        <iframe srcdoc="<script>alert(1)</script>"></iframe>
        <object data="https://evil.test/x.swf"></object>
        <embed src="https://evil.test/x.swf">
        <a id="safe-link" href="https://example.com" target="_top" ping="https://track.test">Safe</a>
        <a id="js-link" href="javascript:alert(1)">JS</a>
        <a id="anchor-link" href="#section-2">Jump</a>
        <form action="javascript:alert(1)" target="_top">
          <input autofocus>
          <button formaction="https://evil.test">Submit</button>
        </form>
        <img src="https://cdn.example.test/pic.png">
        <audio autoplay src="https://cdn.example.test/sound.mp3"></audio>
      HTML

      wrapped = described_class.call(input, blocked_hosts: ["dev.to"], local_http: false)
      doc = Nokogiri::HTML5.parse(wrapped)

      expect(doc.css("base, iframe, object, embed")).to be_empty
      expect(doc.css('meta[http-equiv="refresh"]')).to be_empty
      expect(doc.css('meta[name="referrer"]').pluck("content")).to eq(["no-referrer"])
      expect(doc.css('link[rel="dns-prefetch"]')).to be_empty
      expect(doc.css('link[rel="stylesheet"]')).not_to be_empty

      safe_link = doc.at_css("#safe-link")
      expect(safe_link["href"]).to eq("https://example.com")
      expect(safe_link["target"]).to eq("_blank")
      expect(safe_link["rel"].split).to include("noopener", "noreferrer")
      expect(safe_link["ping"]).to be_nil

      expect(doc.at_css("#js-link")["href"]).to be_nil
      expect(doc.at_css("#anchor-link")["href"]).to eq("#section-2")
      expect(doc.at_css("#anchor-link")["target"]).to be_nil

      form = doc.at_css("form")
      expect(form["action"]).to be_nil
      expect(form["target"]).to be_nil
      expect(doc.at_css("input")["autofocus"]).to be_nil
      expect(doc.at_css("button")["formaction"]).to be_nil

      img = doc.at_css("img")
      expect(img["loading"]).to eq("lazy")
      expect(img["decoding"]).to eq("async")
      expect(doc.at_css("audio")["autoplay"]).to be_nil
    end

    it "escapes </script sequences inside serialized config JSON" do
      wrapped = described_class.call(
        "<p>Hi</p>",
        blocked_hosts: ["dev.to</script><script>alert(1)</script>"],
        local_http: false,
      )

      doc = Nokogiri::HTML5.parse(wrapped)
      wrapper_scripts = doc.css('script[data-forem-wrapper-script="1"]')
      expect(wrapper_scripts.size).to eq(1)
      expect(doc.css("script").size).to eq(1)
    end

    it "renders a safe fallback notice instead of crashing on overly complex HTML", :aggregate_failures do
      deep_html = "#{'<div>' * 300}deep#{'</div>' * 300}"
      wrapped = described_class.call(deep_html, blocked_hosts: ["dev.to"], local_http: false)

      expect(wrapped).to include(I18n.t("services.pages.embed_html_wrapper.complexity_fallback"))
      expect(wrapped).to include('<html lang="en" data-forem-embed="1"')
      expect(described_class.validate_complexity(deep_html)).to eq(:too_deep)

      stub_const("Pages::EmbedHtmlWrapper::MAX_DOM_NODES", 5)
      many_nodes = "<div><span>1</span><span>2</span><span>3</span><span>4</span><span>5</span><span>6</span></div>"
      expect(described_class.validate_complexity(many_nodes)).to eq(:too_many_nodes)
      expect(described_class.call(many_nodes)).to include(
        I18n.t("services.pages.embed_html_wrapper.complexity_fallback"),
      )
    end

    it "propagates unrelated ArgumentError exceptions from tree sanitization" do
      wrapper = described_class.new("<p>Hello</p>", blocked_hosts: [], local_http: false)
      allow(wrapper).to receive(:sanitize_tree!).and_raise(ArgumentError, "unexpected bug")

      expect { wrapper.call }.to raise_error(ArgumentError, "unexpected bug")
    end
  end

  describe ".preview_result" do
    it "returns wrapped HTML within byte limit and 422 when oversized", :aggregate_failures do
      ok = described_class.preview_result("<p>Preview</p>")
      expect(ok[:status]).to eq(:ok)
      expect(ok[:json][:wrapped_html]).to include('data-forem-embed="1"')

      too_big = described_class.preview_result("a" * (Page::MAX_EMBED_HTML_BYTES + 1))
      expect(too_big[:status]).to eq(:unprocessable_entity)
      expect(too_big[:json][:error]).to be_present
    end
  end
end
