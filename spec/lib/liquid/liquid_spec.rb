require "rails_helper"

RSpec.describe Liquid, type: :lib do
  it "is disabled" do
    expect { Liquid::Template.parse("{% liquid %}") }.to raise_error(StandardError)
  end
end
