require "rails_helper"

RSpec.describe Settings::Authentication, type: :model do
  describe "validations" do
    describe "validating domain lists" do
      it "allows valid domain lists" do
        expect do
          described_class.allowed_registration_email_domains = "example.com, example2.com"
        end.not_to raise_error
      end

      it "rejects invalid domain lists" do
        expect do
          described_class.allowed_registration_email_domains = "example.com, e.c"
        end.to raise_error(/must be a comma-separated list of valid domains/)
      end
    end
  end
end
