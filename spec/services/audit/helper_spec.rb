require "rails_helper"

RSpec.describe Audit::Helper, type: :service do
  xit "has a notification suffix" do
    expect(Audit::Helper::NOTIFICATION_SUFFIX).not_to be nil
  end
end
