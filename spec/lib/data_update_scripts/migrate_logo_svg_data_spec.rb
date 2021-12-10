require "rails_helper"
require Rails.root.join(
  "lib/data_update_scripts/20211208074428_migrate_logo_svg_data.rb",
)

describe DataUpdateScripts::MigrateLogoSvgData do
  svg_string = '<svg xmlns="http://www.w3.org/2000/svg"
  width="120" height="120" viewPort="0 0 120 120" version="1.1">
  <rect width="150" height="150" fill="rgb(0, 255, 0)" stroke-width="1" stroke="rgb(0, 0, 0)" />
  <line x1="20" y1="100" x2="100" y2="20" stroke="black" stroke-width="2"/>
  </svg>'

  before do
    allow(Settings::General).to receive(:logo_svg).and_return(svg_string)
    described_class.new.run
  end

  it "returns the logo url with a png extension", :aggregate_failures do
    puts ::Settings::General.original_logo
    expect(::Settings::General.original_logo).to include(".png")
    expect(::Settings::General.resized_logo).to include(".png")
  end
  # The manner in which the uploader behaves is tested by logo_svg_uploader_spec.rb
end
