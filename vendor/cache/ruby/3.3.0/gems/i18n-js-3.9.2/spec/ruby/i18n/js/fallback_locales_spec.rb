require "spec_helper"

describe I18n::JS::FallbackLocales do
  let(:locale) { :fr }
  let(:default_locale) { :en }

  describe "#locales" do
    let(:fallbacks_locales) { described_class.new(fallbacks, locale) }
    subject { fallbacks_locales.locales }

    let(:fetching_locales) { proc do fallbacks_locales.locales end }

    context "when given true as fallbacks" do
      let(:fallbacks) { true }
      it { should eq([default_locale]) }
    end

    context "when given false as fallbacks" do
      let(:fallbacks) { false }
      it { expect(fetching_locales).to raise_error(ArgumentError) }
    end

    context "when given a valid locale as fallbacks" do
      let(:fallbacks) { :de }
      it { should eq([:de]) }
    end

    context "when given a valid Array as fallbacks" do
      let(:fallbacks) { [:de, :en] }
      it { should eq([:de, :en]) }
    end

    context "when given a valid Hash with current locale as key as fallbacks" do
      let(:fallbacks) do { :fr => [:de, :en] } end
      it { should eq([:de, :en]) }
    end

    context "when given a valid Hash without current locale as key as fallbacks" do
      let(:fallbacks) do { :de => [:fr, :en] } end
      it { should eq([default_locale]) }
    end

    context "when given a invalid locale as fallbacks" do
      let(:fallbacks) { :invalid_locale }
      it { should eq([:invalid_locale]) }
    end

    context "when given a invalid type as fallbacks" do
      let(:fallbacks) { 42 }
      it { expect(fetching_locales).to raise_error(ArgumentError) }
    end

    # I18n::Backend::Fallbacks
    context "when I18n::Backend::Fallbacks is used" do
      let(:backend_with_fallbacks) { backend_class_with_fallbacks.new }

      before do
        I18n::JS.backend = backend_with_fallbacks
        I18n.fallbacks[:fr] = [:de, :en]
      end
      after { I18n::JS.backend = I18n::Backend::Simple.new }

      context "given true as fallbacks" do
        let(:fallbacks) { true }
        it { should eq([:de, :en]) }
      end

      context "given :default_locale as fallbacks" do
        let(:fallbacks) { :default_locale }
        it { should eq([:en]) }
      end

      context "given a Hash with current locale as fallbacks" do
        let(:fallbacks) do { :fr => [:en] } end
        it { should eq([:en]) }
      end

      context "given a Hash without current locale as fallbacks" do
        let(:fallbacks) do { :de => [:en] } end
        it { should eq([:de, :en]) }
      end
    end
  end
end
