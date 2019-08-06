require "rails_helper"

RSpec.describe Audit::Notification, type: :service do
  let!(:listener) { Faker::Alphanumeric.alpha(10) }
  let(:user) { build(:user, :admin) }
  let(:queue_name) { Audit::SaveToPersistentStorageJob.queue_name }
  let(:job_class) { Audit::SaveToPersistentStorageJob }

  before do
    Audit::Subscribe.listen listener
  end

  after do
    Audit::Subscribe.forget listener
  end

  def notify
    described_class.notify(listener) do |payload|
      payload.user_id = user.id
      payload.roles = user.roles.pluck(:name)
    end
  end

  describe "Publishing and receiving events" do
    context "when payload is missing" do
      it "event is not created" do
        allow(described_class).to receive(:listen)
        described_class.notify(listener)

        expect(described_class).not_to have_received(:listen)
      end
    end

    context "when payload is present" do
      it "receives an event" do
        allow(described_class).to receive(:listen)
        notify

        expect(described_class).to have_received(:listen)
      end
    end
  end

  describe "Queueing job for saving an event" do
    it "can enqueue job on dedicated queue name" do
      expect { notify }.to have_enqueued_job(job_class).on_queue(queue_name.to_s)
    end
  end

  describe "Saving to database" do
    it "creates an AuditLog record" do
      user.save
      perform_enqueued_jobs do
        notify
      end

      event_record = AuditLog.find_by(user_id: user.id)
      expect(event_record.user).to eq(user)
      expect(event_record.roles).to eq(user.roles.pluck(:name))
    end
  end
end
