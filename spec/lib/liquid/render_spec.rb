require "rails_helper"

# Liquid::Render is disabled by default
# but we want to make sure it's always disabled in the future with an automatic test

RSpec.describe Liquid::Render, type: :lib do
  it "uses the blank file system and it's always disabled" do
    expect(Liquid::Template.file_system).to be_a(Liquid::BlankFileSystem)

    expect { Liquid::Template.parse('{% render "template_name" %}') }.to raise_error(StandardError)
  end
end
