require "rails_helper"

RSpec.describe CodesandboxTag, type: :liquid_tag do
  describe "#id" do
    let(:valid_id) { "22qaa1wcxr" }
    let(:valid_id_with_initialpath) { "68jkdlsaie initialpath=/initial/path/file.js" }
    let(:valid_id_with_module) { "28qvv1wvxr module=/path/to/module.html" }
    let(:valid_id_with_view) { "28qvv1wvxr view=editor" }
    let(:valid_id_with_runonclick) { "28qvv1wvxr runonclick=1" }
    let(:valid_id_with_initialpath_and_module) do
      "43lkjfdauf initialpath=/initial-path/file.js module=/path/to/module.html"
    end
    let(:valid_id_with_initialpath_and_view) { "43lkjfdauf initialpath=/initial-path/file.js view=split" }
    let(:valid_id_with_runonclick_and_module) { "43lkjfdauf runonclick=1 module=/path/to/module.html" }
    let(:valid_id_with_runonclick_and_view) { "28qvv1wvxr runonclick=1 view=preview" }
    let(:valid_id_with_initialpath_and_runonclick) { "43lkjfdauf initialpath=/initial-path/file.js runonclick=1" }
    let(:valid_id_with_initialpath_and_module_and_runonclick) do
      "43lkjfdauf initialpath=/initial-path/file.js module=/path/to/module.html runonclick=1"
    end
    let(:valid_id_with_initialpath_and_module_and_runonclick_and_view) do
      "43lkjfdauf initialpath=/initial-path/file.js module=/path/to/module.html runonclick=1 view=split"
    end
    let(:valid_id_with_special_characters) { "68jkfdsasa initialpath=/.@%_- module=-/%@._" }

    let(:bad_ids) do
      [
        "28qvv1wvxr initialpath=((",
        "22qaa1wcxr module=",
        "22qaa1wcxr runonclick=",
        "22qaa1wcxr runonclick=42836",
        "68jkdlsaie initialpath=uses-a-(",
        "68jkfdsasa initialpath=/uses-a-semi-colon-;",
        "43lkjfdauf module= initialpath=",
        "89fadksjhe random=/stuff",
        "initialpath=/initial/path/file.js",
        "view=foobar",
        "view=",
        "54jfadslkj module=stuff \"onmouseover='alert(\"XSS\")'",
        "42fadfdaf;",
        "%&*($#@$&=",
      ]
    end

    def generate_tag(id)
      Liquid::Template.register_tag("codesandbox", CodesandboxTag)
      Liquid::Template.parse("{% codesandbox #{id} %}")
    end

    it "accepts a vaild id" do
      liquid = generate_tag(valid_id)
      expect(liquid.render).to include("<iframe")
    end

    it "accepts a vaild id with initialpath" do
      liquid = generate_tag(valid_id_with_initialpath)
      expect(liquid.render).to include("<iframe")
    end

    it "accepts a vaild id with module" do
      liquid = generate_tag(valid_id_with_module)
      expect(liquid.render).to include("<iframe")
    end

    it "accepts a vaild id with view" do
      liquid = generate_tag(valid_id_with_view)
      expect(liquid.render).to include("<iframe")
    end

    it "accepts a vaild id with runonclick" do
      liquid = generate_tag(valid_id_with_runonclick)
      expect(liquid.render).to include("<iframe")
    end

    it "accepts a vaild id with initialpath and module" do
      liquid = generate_tag(valid_id_with_initialpath_and_module)
      expect(liquid.render).to include("<iframe")
    end

    it "accepts a vaild id with initialpath and view" do
      liquid = generate_tag(valid_id_with_initialpath_and_view)
      expect(liquid.render).to include("<iframe")
    end

    it "accepts a vaild id with initialpath and runonclick" do
      liquid = generate_tag(valid_id_with_initialpath_and_runonclick)
      expect(liquid.render).to include("<iframe")
    end

    it "accepts a vaild id with runonclick and module" do
      liquid = generate_tag(valid_id_with_runonclick_and_module)
      expect(liquid.render).to include("<iframe")
    end

    it "accepts a vaild id with runonclick and view" do
      liquid = generate_tag(valid_id_with_runonclick_and_view)
      expect(liquid.render).to include("<iframe")
    end

    it "accepts a vaild id with initialpath and module and runonclick" do
      liquid = generate_tag(valid_id_with_initialpath_and_module_and_runonclick)
      expect(liquid.render).to include("<iframe")
    end

    it "accepts a vaild id with initialpath and module and runonclick and view" do
      liquid = generate_tag(valid_id_with_initialpath_and_module_and_runonclick_and_view)
      expect(liquid.render).to include("<iframe")
    end

    it "accepts a vaild id with special_characters of / . @ % _" do
      liquid = generate_tag(valid_id_with_special_characters)
      expect(liquid.render).to include("<iframe")
    end

    it "rejects bad ids" do
      bad_ids.each do |id|
        expect { generate_tag(id) }.to raise_error(StandardError)
      end
    end
  end
end
