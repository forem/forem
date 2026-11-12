require "rails_helper"

RSpec.describe "InstantClick layout and inline script safety" do
  describe "GET /" do
    it "marks one-time shell scripts with data-no-instant and avoids global const isEmbeddedFrame declarations" do
      user = create(:user)
      sign_in user

      get "/"

      expect(response).to have_http_status(:ok)
      doc = Nokogiri::HTML5(response.body)

      embed_scripts = doc.css("body script").select { |node| node.text.include?("isEmbeddedFrame") }
      expect(embed_scripts).not_to be_empty
      embed_scripts.each do |script_node|
        expect(script_node.has_attribute?("data-no-instant")).to be(true)
      end

      color_mode_scripts = doc.css("body script").select { |node| node.text.include?("watchColorModeChanges") }
      expect(color_mode_scripts).not_to be_empty
      color_mode_scripts.each do |script_node|
        expect(script_node.has_attribute?("data-no-instant")).to be(true)
      end
    end
  end

  describe "ERB inline script lexical scope hygiene" do
    it "avoids top-level const, let, or class bindings in InstantClick ERB inline scripts" do
      standalone_views = Set.new(["app/views/deep_links/mobile.html.erb"])

      offenders = []

      Rails.root.glob("app/views/**/*.erb").sort.each do |erb_path|
        rel_path = erb_path.relative_path_from(Rails.root).to_s
        next if standalone_views.include?(rel_path)

        content = erb_path.read
        content.scan(%r{<script(?![^>]*type=["'](?:application/ld\+json|text/x-tmpl))[^>]*>(.*?)</script>}mi) do |match|
          clean_js = match.first.gsub(/<%.*?%>/m, "")
          brace_depth = 0

          clean_js.each_line do |line|
            stripped = line.strip
            if brace_depth.zero? && stripped.match?(/\A(?:const|let|class)\s+[A-Za-z_$]/)
              offenders << "#{rel_path}: #{stripped[0, 80]}"
            end
            brace_depth += line.count("{") - line.count("}")
          end
        end
      end

      expect(offenders).to be_empty
    end
  end
end
