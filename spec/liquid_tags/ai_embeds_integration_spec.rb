require "rails_helper"

# rubocop:disable RSpec/DescribeClass
RSpec.describe "AI embed liquid tags integration", type: :liquid_tag do
  describe "UnifiedEmbed registry" do
    [
      ["https://my-space.hf.space", HuggingfaceTag],
      ["https://huggingface.co/spaces/user/space", HuggingfaceTag],
      ["https://huggingface.co/datasets/fka/awesome-chatgpt-prompts", HuggingfaceTag],

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

  describe "rendering through {% embed %} tag" do
    [
      ["https://my-space.hf.space", "ltag__huggingface"],

      ["https://my-project.bolt.host", "ltag__bolt"],
      ["https://my-app.lovable.app", "ltag__lovable"],
      ["https://abc123def.vusercontent.net", "ltag__v0"],
      ["https://app.warp.dev/block/abc123", "ltag__warp"],
    ].each do |url, expected_class|
      it "renders #{expected_class} for #{url}" do
        stub_request(:head, url).to_return(status: 200, body: "", headers: {})
        liquid = Liquid::Template.parse("{% embed #{url} %}")
        expect(liquid.render).to include(expected_class)
      end
    end
  end
end
# rubocop:enable RSpec/DescribeClass
