require "rails_helper"

RSpec.describe "AI embed liquid tags integration", type: :liquid_tag do
  describe "Liquid::Template registration" do
    it "registers all AI embed tags" do
      tags = Liquid::Template.tags
      expect(tags["claudeartifact"]).to eq(ClaudeArtifactTag)
      expect(tags["huggingface"]).to eq(HuggingfaceTag)
      expect(tags["streamlit"]).to eq(StreamlitTag)
      expect(tags["bolt"]).to eq(BoltTag)
      expect(tags["lovable"]).to eq(LovableTag)
      expect(tags["v0"]).to eq(V0Tag)
      expect(tags["warp"]).to eq(WarpTag)
    end
  end

  describe "UnifiedEmbed registry" do
    [
      ["https://claude.site/artifacts/192abf2c-315d-4938-ae6c-6125157e44f0", ClaudeArtifactTag],
      ["https://my-space.hf.space", HuggingfaceTag],
      ["https://huggingface.co/spaces/user/space", HuggingfaceTag],
      ["https://my-app.streamlit.app", StreamlitTag],
      ["https://project.bolt.host", BoltTag],
      ["https://bolt.new/~/my-project", BoltTag],
      ["https://my-app.lovable.app", LovableTag],
      ["https://abc123.vusercontent.net", V0Tag],
      ["https://v0.dev/chat/my-project-abc", V0Tag],
      ["https://app.warp.dev/block/abc123", WarpTag],
    ].each do |url, expected_klass|
      it "routes #{url} to #{expected_klass}" do
        handler = UnifiedEmbed::Registry.find_liquid_tag_for(link: url)
        expect(handler).to eq(expected_klass)
      end
    end
  end
end
