require "rails_helper"

RSpec.describe EmailDigest, type: :service do
  def digest_subscriber(**attrs)
    create(:user, **attrs).tap do |user|
      user.notification_setting.update(email_digest_periodic: true)
    end
  end

  describe "::send_digest_email" do
    it "enqueues Emails::SendUserDigestWorker" do
      user = digest_subscriber
      allow(Emails::SendUserDigestWorker).to receive(:perform_async)
      described_class.send_periodic_digest_email
      expect(Emails::SendUserDigestWorker).to have_received(:perform_async).with(user.id)
    end

    it "performs job inline if community is DEV" do
      allow(ForemInstance).to receive(:dev_to?).and_return(true)
      user = digest_subscriber
      worker = Emails::SendUserDigestWorker.new
      allow(worker).to receive(:perform)
      allow(Emails::SendUserDigestWorker).to receive(:new).and_return(worker)
      allow(Emails::SendUserDigestWorker).to receive(:perform_async)
      described_class.send_periodic_digest_email
      expect(Emails::SendUserDigestWorker).not_to have_received(:perform_async)
      expect(worker).to have_received(:perform).with(user.id)
    end
  end

  describe "eligibility" do
    before { allow(Emails::SendUserDigestWorker).to receive(:perform_async) }

    it "skips suspended users" do
      user = digest_subscriber
      user.add_role(:suspended)

      described_class.send_periodic_digest_email

      expect(Emails::SendUserDigestWorker).not_to have_received(:perform_async).with(user.id)
    end

    it "skips spam users" do
      user = digest_subscriber
      user.add_role(:spam)

      described_class.send_periodic_digest_email

      expect(Emails::SendUserDigestWorker).not_to have_received(:perform_async).with(user.id)
    end

    # Banishing suspends and renames the account but leaves the digest consent
    # in place, so the role filter is what catches it -- see
    # Moderator::BanishUser.
    it "skips banished users" do
      user = digest_subscriber
      Moderator::BanishUser.call(admin: create(:user, :super_admin), user: user)

      described_class.send_periodic_digest_email

      expect(Emails::SendUserDigestWorker).not_to have_received(:perform_async).with(user.id)
    end

    it "still includes users who have not opted into the newsletter" do
      user = digest_subscriber
      user.notification_setting.update(email_newsletter: false)

      described_class.send_periodic_digest_email

      expect(Emails::SendUserDigestWorker).to have_received(:perform_async).with(user.id)
    end

    it "honours the id range so the sharded cron still partitions" do
      user = digest_subscriber

      described_class.send_periodic_digest_email([], user.id + 1, user.id + 100)

      expect(Emails::SendUserDigestWorker).not_to have_received(:perform_async).with(user.id)
    end
  end
end
