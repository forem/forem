require "rails_helper"

describe BulkSqlDelete, type: :service do
  let(:sql) do
    <<-SQL
      DELETE FROM notifications
      WHERE notifications.id IN (
        SELECT notifications.id
        FROM notifications
        WHERE created_at < '#{Time.zone.now}'
        LIMIT 1
      )
    SQL
  end
  let(:logger) { Rails.logger }

  before { allow(Rails).to receive(:logger).and_return(logger) }

  describe "#delete_in_batches" do
    it "logs batch deletion" do
      create_list :notification, 5
      allow(logger).to receive(:info).exactly(6).times.with(
        hash_including(:tag, :statement, :duration, :rows_deleted),
      )
      described_class.delete_in_batches(sql)
      expect(logger).to have_received(:info).exactly(6).times.with(
        hash_including(:tag, :statement, :duration, :rows_deleted),
      )
    end

    it "logs errors that occur" do
      allow(logger).to receive(:error).with(
        hash_including(:tag, :statement, :exception_message, :backtrace),
      )
      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter).to receive(:exec_delete).and_raise("broken")
      # rubocop:enable RSpec/AnyInstance

      expect { described_class.delete_in_batches(sql) }.to raise_error("broken")
      expect(logger).to have_received(:error).with(
        hash_including(:tag, :statement, :exception_message, :backtrace),
      )
    end

    it "deletes all records in batches" do
      create_list :notification, 10
      expect { described_class.delete_in_batches(sql) }.to change(Notification, :count).from(10).to(0)
    end
  end
end
