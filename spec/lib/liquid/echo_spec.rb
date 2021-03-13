require "rails_helper"

# Liquid::Echo internally uses Liquid::Variable which we disable,
# but we want to make sure it always is disabled in turn

RSpec.describe Liquid::Echo, type: :lib do
  it "is disabled" do
    expect { Liquid::Template.parse("{% echo something %}") }.to raise_error(StandardError)
  end
end
