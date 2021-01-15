require "rails_helper"

RSpec.describe Liquid::Render, type: :lib do
  # Liquid::Render is disabled by default
  # but we want to make sure it's always disabled in the future with an automatic test
  it "uses the blank file system and it's always disabled" do
    expect(Liquid::Template.file_system).to be_a(Liquid::BlankFileSystem)

    error_message = "Liquid error: This liquid context does not allow includes"
    expect(Liquid::Template.parse('{% render "template_name" %}').render).to match(error_message)
  end
end
