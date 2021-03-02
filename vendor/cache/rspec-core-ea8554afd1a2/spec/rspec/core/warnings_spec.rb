RSpec.describe "rspec warnings and deprecations" do

  describe "#deprecate" do
    it "passes the hash to the reporter" do
      expect(RSpec.configuration.reporter).to receive(:deprecation).with(hash_including :deprecated => "deprecated_method", :replacement => "replacement")
      RSpec.deprecate("deprecated_method", :replacement => "replacement")
    end

    it "adds the call site" do
      expect_deprecation_with_call_site(__FILE__, __LINE__ + 1)
      RSpec.deprecate("deprecated_method")
    end

    it "doesn't override a passed call site" do
      expect_deprecation_with_call_site("some_file.rb", 17)
      RSpec.deprecate("deprecated_method", :call_site => "/some_file.rb:17")
    end
  end

  describe "#warn_deprecation" do
    it "puts message in a hash" do
      expect(RSpec.configuration.reporter).to receive(:deprecation).with(hash_including :message => "this is the message")
      RSpec.warn_deprecation("this is the message")
    end

    it "passes along additional options" do
      expect(RSpec.configuration.reporter).to receive(:deprecation).with(hash_including :type => :tag)
      RSpec.warn_deprecation("this is the message", :type => :tag)
    end
  end

  describe "#warn_with" do
    context "when :use_spec_location_as_call_site => true is passed" do
      let(:options) do
        {
          :use_spec_location_as_call_site => true,
          :call_site                      => nil,
        }
      end

      it "adds the source location of spec" do
        line = __LINE__ - 1
        file_path = RSpec::Core::Metadata.relative_path(__FILE__)
        expect(Kernel).to receive(:warn).with(/The warning. Warning generated from spec at `#{file_path}:#{line}`./)

        RSpec.warn_with("The warning.", options)
      end

      it "appends a period to the supplied message if one is not present" do
        line = __LINE__ - 1
        file_path = RSpec::Core::Metadata.relative_path(__FILE__)
        expect(Kernel).to receive(:warn).with(/The warning. Warning generated from spec at `#{file_path}:#{line}`./)

        RSpec.warn_with("The warning", options)
      end

      context "when there is no current example" do
        before do
          allow(RSpec).to receive(:current_example).and_return(nil)
        end

        it "adds no message about the spec location" do
          expect(Kernel).to receive(:warn).with(/The warning\.$/)

          RSpec.warn_with("The warning.", options)
        end
      end
    end
  end
end
