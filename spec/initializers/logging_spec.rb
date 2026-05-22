require "rails_helper"

RSpec.describe "Logging Configuration" do
  it "successfully defines Logger class and severity constants" do
    expect(defined?(Logger)).to eq("constant")
    expect(defined?(Logger::Severity)).to eq("constant")
  end

  it "successfully loads ActiveSupport::Logger without NameError" do
    expect(defined?(ActiveSupport::Logger)).to eq("constant")
    expect(ActiveSupport::Logger.new(IO::NULL)).to be_a(ActiveSupport::Logger)
  end
end
