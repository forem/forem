require "rails_helper"
require "tmpdir"
require_relative "../support/rspec_retry_csv_report"

RSpec.describe RSpecRetryCsvReport do
  describe ".write" do
    it "does not create a report when no examples were retried" do
      Dir.mktmpdir do |directory|
        report = described_class.write(rows: [], suite_status: :passed, suite_runtime: 1.25, directory: directory)

        expect(report).to be_nil
        expect(Dir.children(directory)).to be_empty
      end
    end

    it "writes only retry rows with the final suite result" do
      retry_row = [
        "retried example",
        "./spec/example_spec.rb:10",
        :failed,
        "07-28-2026",
        "12-00-00.000",
        0.5,
        "failure",
        "backtrace",
        1,
      ]

      Dir.mktmpdir do |directory|
        report = described_class.write(
          rows: [retry_row],
          suite_status: :passed,
          suite_runtime: 2.5,
          directory: directory,
          timestamp: Time.utc(2026, 7, 28, 12),
          process_id: 123,
        )
        csv = CSV.read(report, headers: true)

        expect(csv.headers).to eq(described_class::HEADERS)
        expect(csv.first.fields.first(9)).to eq(retry_row.map(&:to_s))
        expect(csv.first["Suite Status"]).to eq("passed")
        expect(csv.first["Suite Run Time"]).to eq("2.5")
      end
    end
  end
end
