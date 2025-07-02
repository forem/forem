require "rails_helper"

RSpec.describe Liquid::Variable, type: :lib do
  it "renders the raw Liquid variable as text" do
    variable = described_class.new("user.name", nil)
    expect(variable.render(nil)).to eq("{{user.name}}")
  end
end