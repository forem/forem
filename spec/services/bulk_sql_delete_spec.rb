require "rails_helper"

describe BulkSqlDelete, type: :service do
  let(:sql) do
    <<-SQL.squish
      DELETE FROM notifications
      WHERE notifications.id IN (
        SELECT notifications.id
        FROM notifications
        WHERE created_at < '#{Time.current}'
        LIMIT 1
      )
    SQL
  end
  let(:logger) { Rails.logger }

  before { allow(Rails).to receive(:logger).and_return(logger) }

  describe "#delete_in_batches" do
    it "logs batch deletion" do
      create_list(:notification, 3, created_at: 1.month.ago)
      allow(logger).to receive(:info)
      described_class.delete_in_batches(sql)
      expect(logger).to have_received(:info).exactly(4).times.with(
        hash_including(:tag, :statement, :duration, :rows_deleted),
      )
    end

    it "logs errors that occur" do
      allow(logger).to receive(:error)
      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
        .to(receive(:exec_delete)).and_raise("broken")
      # rubocop:enable RSpec/AnyInstance

      expect { described_class.delete_in_batches(sql) }.to raise_error("broken")
      expect(logger).to have_received(:error).with(
        hash_including(:tag, :statement, :exception_message, :backtrace),
      )
    end

    it "deletes all records in batches" do
      create_list(:notification, 5, created_at: 1.month.ago)
      result = described_class.delete_in_batches(sql)
      expect(result).to eq(5)
    end
  end
end
