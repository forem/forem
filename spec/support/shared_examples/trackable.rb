# Shared examples for any model that includes the Trackable concern.
#
# Usage:
#   RSpec.describe MyModel do
#     subject { build(:my_model) }
#     it_behaves_like "trackable"
#   end
shared_examples_for "trackable" do
  it "includes the Trackable concern" do
    expect(subject.class.included_modules).to include(Trackable)
  end

  describe "#trackable_user_ids" do
    it "is defined and returns a non-empty value" do
      subject.save! unless subject.persisted?
      ids = Array.wrap(subject.trackable_user_ids).compact

      expect(ids).not_to be_empty
    end
  end

  describe "lifecycle event firing" do
    let(:stub_adapter) do
      instance_double(Trackers::Base, enabled?: true).tap { |a| allow(a).to receive(:track) }
    end

    before do
      allow(Trackable::Registry).to receive(:active_names).and_return([:any])
      allow(Trackable::DispatchWorker).to receive(:perform_async)
    end

    around { |ex| with_trackable_events { ex.run } }

    it "enqueues a model_updated event after a non-touch-only change" do
      subject.save! unless subject.persisted?
      subject.touch # baseline; should not enqueue

      # Trigger a real change. The shared example caller is responsible for the
      # subject having at least one writable, non-touch attribute.
      changeable_attr = (subject.class.attribute_names - Trackable::TOUCH_ONLY_KEYS - %w[id created_at]).first
      raise "subject has no changeable attribute for trackable shared example" unless changeable_attr

      subject.update!(changeable_attr => "#{subject[changeable_attr]}_x")

      param_key = subject.class.model_name.param_key
      expect(Trackable::DispatchWorker).to have_received(:perform_async).with(
        anything, "#{param_key}_updated", anything, anything, anything
      )
    end
  end
end
