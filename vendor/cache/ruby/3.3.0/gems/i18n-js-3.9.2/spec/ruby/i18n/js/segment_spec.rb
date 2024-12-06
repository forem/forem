require "spec_helper"

describe I18n::JS::Segment do

  let(:file)        { "tmp/i18n-js/segment.js" }
  let(:translations){ { en: { "test" => "Test" }, fr: { "test" => "Test2" } } }
  let(:namespace)   { "MyNamespace" }
  let(:pretty_print){ nil }
  let(:json_only)  { nil }
  let(:js_extend)  { nil }
  let(:sort_translation_keys){ nil }
  let(:options)     { { namespace: namespace,
                        pretty_print: pretty_print,
                        json_only: json_only,
                        js_extend: js_extend,
                        sort_translation_keys: sort_translation_keys }.delete_if{|k,v| v.nil?} }
  subject { I18n::JS::Segment.new(file, translations, options) }

  describe ".new" do

    it "should persist the file path variable" do
      expect(subject.file).to eql("tmp/i18n-js/segment.js")
    end

    it "should persist the translations variable" do
      expect(subject.translations).to eql(translations)
    end

    it "should persist the namespace variable" do
      expect(subject.namespace).to eql("MyNamespace")
    end

    context "when namespace is nil" do
      let(:namespace){ nil }

      it "should default namespace to `I18n`" do
        expect(subject.namespace).to eql("I18n")
      end
    end

    context "when namespace is not set" do
      subject { I18n::JS::Segment.new(file, translations) }

      it "should default namespace to `I18n`" do
        expect(subject.namespace).to eql("I18n")
      end
    end

    context "when pretty_print is nil" do
      it "should set pretty_print to false" do
        expect(subject.pretty_print).to be false
      end
    end

    context "when pretty_print is truthy" do
      let(:pretty_print){ 1 }

      it "should set pretty_print to true" do
        expect(subject.pretty_print).to be true
      end
    end
  end

  describe "#saving!" do
    before { allow(I18n::JS).to receive(:export_i18n_js_dir_path).and_return(temp_path) }

    context "when json_only is true with locale" do
      let(:file){ "tmp/i18n-js/%{locale}.js" }
      let(:json_only){ true }

      it 'should output JSON files per locale' do
        subject.save!
        file_should_exist "en.js"
        file_should_exist "fr.js"

        expect(File.read(File.join(temp_path, "en.js"))).to eql(
          %Q({"en":{"test":"Test"}})
        )

        expect(File.read(File.join(temp_path, "fr.js"))).to eql(
          %Q({"fr":{"test":"Test2"}})
        )
      end
    end

    context "when json_only is true without locale" do
      let(:file){ "tmp/i18n-js/segment.js" }
      let(:json_only){ true }

      it 'should output one JSON file for all locales' do
        subject.save!
        file_should_exist "segment.js"

        expect(File.read(File.join(temp_path, "segment.js"))).to eql(
          %Q({"en":{"test":"Test"},"fr":{"test":"Test2"}})
        )
      end
    end

    context "when json_only and pretty print are true" do
      let(:file){ "tmp/i18n-js/segment.js" }
      let(:json_only){ true }
      let(:pretty_print){ true }

      it 'should output one JSON file for all locales' do
        subject.save!
        file_should_exist "segment.js"

        expect(File.read(File.join(temp_path, "segment.js"))).to eql <<-EOS
{
  "en": {
    "test": "Test"
  },
  "fr": {
    "test": "Test2"
  }
}
EOS
.chomp
      end
    end
  end

  describe "#save!" do
    before { allow(I18n::JS).to receive(:export_i18n_js_dir_path).and_return(temp_path) }
    before { subject.save! }

    context "when file does not include %{locale}" do
      it "should write the file" do
        file_should_exist "segment.js"

        expect(File.open(File.join(temp_path, "segment.js")){|f| f.read}).to eql <<-EOF
MyNamespace.translations || (MyNamespace.translations = {});
MyNamespace.translations["en"] = I18n.extend((MyNamespace.translations["en"] || {}), JSON.parse('{"test":"Test"}'));
MyNamespace.translations["fr"] = I18n.extend((MyNamespace.translations["fr"] || {}), JSON.parse('{"test":"Test2"}'));
        EOF
      end
    end

    context "when file includes %{locale}" do
      let(:file){ "tmp/i18n-js/%{locale}.js" }

      it "should write files" do
        file_should_exist "en.js"
        file_should_exist "fr.js"

        expect(File.open(File.join(temp_path, "en.js")){|f| f.read}).to eql <<-EOF
MyNamespace.translations || (MyNamespace.translations = {});
MyNamespace.translations["en"] = I18n.extend((MyNamespace.translations["en"] || {}), JSON.parse('{"test":"Test"}'));
        EOF

        expect(File.open(File.join(temp_path, "fr.js")){|f| f.read}).to eql <<-EOF
MyNamespace.translations || (MyNamespace.translations = {});
MyNamespace.translations["fr"] = I18n.extend((MyNamespace.translations["fr"] || {}), JSON.parse('{"test":"Test2"}'));
        EOF
      end
    end

    context "when file includes single quote" do
      let(:file){ "tmp/i18n-js/%{locale}.js" }
      let(:translations){ { en: { "a" => "Test's" } } }

      it "should write files" do
        file_should_exist "en.js"

        expect(File.open(File.join(temp_path, "en.js")){|f| f.read}).to eql <<-EOF
MyNamespace.translations || (MyNamespace.translations = {});
MyNamespace.translations["en"] = I18n.extend((MyNamespace.translations["en"] || {}), JSON.parse('{"a":"Test\\'s"}'));
        EOF
      end
    end

    context "when file includes escaped double quote" do
      let(:file){ "tmp/i18n-js/%{locale}.js" }
      let(:translations){ { en: { "a" => 'say "hello"' } } }

      it "should escape double quote" do
        file_should_exist "en.js"

        expect(File.open(File.join(temp_path, "en.js")){|f| f.read}).to eql <<-EOF
MyNamespace.translations || (MyNamespace.translations = {});
MyNamespace.translations["en"] = I18n.extend((MyNamespace.translations["en"] || {}), JSON.parse('{"a":"say \\\\"hello\\\\""}'));
        EOF
      end
    end

    context "when file includes backslash in double quote" do
      let(:file){ "tmp/i18n-js/%{locale}.js" }
      let(:translations){ { en: { "double-backslash-in-double-quote" => '"\\\\"' } } }

      it "should escape backslash" do
        file_should_exist "en.js"

        expect(File.open(File.join(temp_path, "en.js")){|f| f.read}).to eql <<-EOF
MyNamespace.translations || (MyNamespace.translations = {});
MyNamespace.translations["en"] = I18n.extend((MyNamespace.translations["en"] || {}), JSON.parse('{"double-backslash-in-double-quote":"\\\\"\\\\\\\\\\\\\\\\\\\\""}'));
        EOF
      end
    end

    context "when js_extend is true" do
      let(:js_extend){ true }

      let(:translations){ { en: { "b" => "Test", "a" => "Test" } } }

      it 'should output the keys as sorted' do
        file_should_exist "segment.js"

        expect(File.open(File.join(temp_path, "segment.js")){|f| f.read}).to eql <<-EOF
MyNamespace.translations || (MyNamespace.translations = {});
MyNamespace.translations["en"] = I18n.extend((MyNamespace.translations["en"] || {}), JSON.parse('{"a":"Test","b":"Test"}'));
        EOF
      end
    end

    context "when js_extend is false" do
      let(:js_extend){ false }

      let(:translations){ { en: { "b" => "Test", "a" => "Test" } } }

      it 'should output the keys as sorted' do
        file_should_exist "segment.js"

        expect(File.open(File.join(temp_path, "segment.js")){|f| f.read}).to eql <<-EOF
MyNamespace.translations || (MyNamespace.translations = {});
MyNamespace.translations["en"] = JSON.parse('{"a":"Test","b":"Test"}');
        EOF
      end
    end

    context "when sort_translation_keys is true" do
      let(:sort_translation_keys){ true }

      let(:translations){ { en: { "b" => "Test", "a" => "Test" } } }

      it 'should output the keys as sorted' do
        file_should_exist "segment.js"

        expect(File.open(File.join(temp_path, "segment.js")){|f| f.read}).to eql <<-EOF
MyNamespace.translations || (MyNamespace.translations = {});
MyNamespace.translations["en"] = I18n.extend((MyNamespace.translations["en"] || {}), JSON.parse('{"a":"Test","b":"Test"}'));
        EOF
      end
    end

    context "when sort_translation_keys is false" do
      let(:sort_translation_keys){ false }

      let(:translations){ { en: { "b" => "Test", "a" => "Test" } } }

      it 'should output the keys as sorted' do
        file_should_exist "segment.js"

        expect(File.open(File.join(temp_path, "segment.js")){|f| f.read}).to eql <<-EOF
MyNamespace.translations || (MyNamespace.translations = {});
MyNamespace.translations["en"] = I18n.extend((MyNamespace.translations["en"] || {}), JSON.parse('{"b":"Test","a":"Test"}'));
        EOF
      end
    end

    context "when translation entries contain procs" do
      let(:translations) do
        {
          en: {
            "test" => "Test",
            "i18n" => {"plural" => {"rule" => proc {} }},
          },
          fr: {
            "test" => "Test2",
            "i18n" => {"plural" => {"rule" => proc {} }},
          },
        }
      end

      it "should write files without procs or their string representations" do
        file_should_exist "segment.js"

        expect(File.open(File.join(temp_path, "segment.js")){|f| f.read}).to eql <<-EOF
MyNamespace.translations || (MyNamespace.translations = {});
MyNamespace.translations["en"] = I18n.extend((MyNamespace.translations["en"] || {}), JSON.parse('{"i18n":{"plural":{}},"test":"Test"}'));
MyNamespace.translations["fr"] = I18n.extend((MyNamespace.translations["fr"] || {}), JSON.parse('{"i18n":{"plural":{}},"test":"Test2"}'));
        EOF
      end
    end
  end
end
