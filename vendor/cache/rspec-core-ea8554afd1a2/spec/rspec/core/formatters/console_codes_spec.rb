require 'rspec/core/formatters/console_codes'

RSpec.describe "RSpec::Core::Formatters::ConsoleCodes" do
  let(:console_codes) { RSpec::Core::Formatters::ConsoleCodes }

  describe "#console_code_for(code_or_symbol)" do
    context "when given a VT100 integer code" do
      it "returns the code" do
        expect(console_codes.console_code_for(32)).to eq 32
      end
    end

    context "when given a symbolic name" do
      it "returns the code" do
        expect(console_codes.console_code_for(:green)).to eq 32
      end
    end

    context "when given an rspec code" do
      it "returns the console code" do
        RSpec.configuration.success_color = :blue # blue is 34
        expect(console_codes.console_code_for(:success)).to eq 34
      end
    end

    context "when given a nonexistant code" do
      it "returns the code for white" do
        expect(console_codes.console_code_for(:octarine)).to eq 37
      end
    end
  end

  describe "#wrap" do
    before do
      allow(RSpec.configuration).to receive(:color_enabled?) { true }
    end

    context "when given a VT100 integer code" do
      it "formats the text with it" do
        expect(console_codes.wrap('abc', 32)).to eq "\e[32mabc\e[0m"
      end
    end

    context "when given a symbolic color name" do
      it "translates it to the correct integer code and formats the text with it" do
        expect(console_codes.wrap('abc', :green)).to eq "\e[32mabc\e[0m"
      end
    end

    context "when given an rspec code" do
      it "returns the console code" do
        RSpec.configuration.success_color = :blue # blue is 34
        expect(console_codes.wrap('abc', :success)).to eq "\e[34mabc\e[0m"
      end
    end


    context "when given :bold" do
      it "formats the text as bold" do
        expect(console_codes.wrap('abc', :bold)).to eq "\e[1mabc\e[0m"
      end
    end
  end
end
