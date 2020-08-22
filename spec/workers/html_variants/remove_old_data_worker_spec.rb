require "rails_helper"

RSpec.describe HtmlVariants::RemoveOldDataWorker, type: :worker do
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "low_priority"

  describe "#perform" do
    it "removes old html variants" do
      Timecop.freeze do
        old_trial_id = create(:html_variant_trial, created_at: 1.month.ago).id
        old_success_id = create(:html_variant_success, created_at: 1.month.ago).id
        new_trial = create(:html_variant_trial, created_at: Time.current)
        new_trial.html_variant.update(success_rate: 0)

        worker.perform

        expect(HtmlVariantTrial.find_by(id: old_trial_id)).to be_nil
        expect(HtmlVariantSuccess.find_by(id: old_success_id)).to be_nil
        expect(HtmlVariantTrial.find_by(id: new_trial.id)).not_to be_nil
      end
    end
  end
end
