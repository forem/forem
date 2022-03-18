require "rails_helper"

RSpec.describe Audit::Helper, type: :service do
  it "has a notification suffix" do
    expect(Audit::Helper::NOTIFICATION_SUFFIX).not_to be_nil
  end
end
