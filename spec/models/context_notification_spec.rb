require "rails_helper"

RSpec.describe ContextNotification do
  let(:context_notification) { create(:context_notification) }

  describe "validations" do
    describe "builtin validations" do
      subject { context_notification }

      it { is_expected.to be_valid }
      it { is_expected.to belong_to(:context) }
      it { is_expected.to validate_presence_of(:action) }
      it { is_expected.to validate_presence_of(:context_type) }

      it { is_expected.to validate_uniqueness_of(:context_id).scoped_to(%i[context_type action]) }
    end

    it "is invalid with a Comment as context" do
      context_notification.context_type = "Comment"
      expect(context_notification.valid?).to be false
    end
  end
end
