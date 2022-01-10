require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20220105112823_migrate_logo_svg_data.rb",
)

describe DataUpdateScripts::MigrateLogoSvgData do
  # This simply tests the output of the script, however,
  # the manner in which the uploader behaves is tested by logo_svg_uploader_spec.rb

  context "when the svg is able to be processed" do
    processable_svg_string = '<svg xmlns="http://www.w3.org/2000/svg"
    width="120" height="120" viewPort="0 0 120 120" version="1.1">
    <rect width="150" height="150" fill="rgb(0, 255, 0)" stroke-width="1" stroke="rgb(0, 0, 0)" />
    <line x1="20" y1="100" x2="100" y2="20" stroke="black" stroke-width="2"/>
    </svg>'

    it "returns the logo url with a png extension", :aggregate_failures do
      allow(Settings::General).to receive(:logo_svg).and_return(processable_svg_string)
      described_class.new.run

      expect(::Settings::General.original_logo).to include(".png")
      expect(::Settings::General.resized_logo).to include(".png")
    end
  end

  context "when the svg is unable to be processed" do
    # rubocop:disable Layout/LineLength
    unprocessable_svg_string = '<svg width="50" height="40" viewBox="0 0 50 40" fill="none" xmlns="http://www.w3.org/2000/svg"><rect width="50" height="40" rx="3" style="fill: currentColor;"></rect><path d="M19.099 23.508c0 1.31-.423 2.388-1.27 3.234-.838.839-1.942 1.258-3.312 1.258h-4.403V12.277h4.492c1.31 0 2.385.423 3.224 1.27.846.838 1.269 1.912 1.269 3.223v6.738zm-2.808 0V16.77c0-.562-.187-.981-.562-1.258-.374-.285-.748-.427-1.122-.427h-1.685v10.107h1.684c.375 0 .75-.138 1.123-.415.375-.285.562-.708.562-1.27zM28.185 28h-5.896c-.562 0-1.03-.187-1.404-.561-.375-.375-.562-.843-.562-1.404V14.243c0-.562.187-1.03.562-1.404.374-.375.842-.562 1.404-.562h5.896v2.808H23.13v3.65h3.088v2.808h-3.088v3.65h5.054V28zm7.12 0c-.936 0-1.684-.655-2.246-1.965l-3.65-13.758h3.089l2.807 10.804 2.808-10.804H41.2l-3.65 13.758C36.99 27.345 36.241 28 35.305 28z" style="fill: var(--base-inverted);"></path></svg>'
    # rubocop:enable Layout/LineLength

    it "logs an error" do
      allow(Settings::General).to receive(:logo_svg).and_return(unprocessable_svg_string)
      allow(Honeybadger).to receive(:notify)
      allow(LogoSvgUploader).to receive(:new).and_raise(StandardError)

      described_class.new.run
      expect(Honeybadger).to have_received(:notify).once
      expect(::Settings::General.original_logo).to be(nil)
      expect(::Settings::General.resized_logo).to be(nil)
    end
  end
end
