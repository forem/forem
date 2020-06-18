require "rails_helper"

RSpec.describe Liquid::Variable, type: :lib do
  it "does not allow instantiation" do
    expect { described_class.new("", nil) }.to raise_error(StandardError, /variables are disabled/)
  end
end
