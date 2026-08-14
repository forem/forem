require "rails_helper"

RSpec.describe CaptureQueryStatsWorker, type: :worker do
  subject(:worker) { described_class.new }

  describe "#perform" do
    context "when PG_HERO_CAPTURE_QUERY_STATS is not set" do
      before { stub_const("ENV", ENV.to_h.merge("PG_HERO_CAPTURE_QUERY_STATS" => nil)) }

      it "does not capture query stats" do
        allow(PgHero).to receive(:capture_query_stats)
        worker.perform
        expect(PgHero).not_to have_received(:capture_query_stats)
      end
    end

    context "when PG_HERO_CAPTURE_QUERY_STATS is set to 'true'" do
      before { stub_const("ENV", ENV.to_h.merge("PG_HERO_CAPTURE_QUERY_STATS" => "true")) }

      it "captures query stats via PgHero" do
        allow(PgHero).to receive(:capture_query_stats)
        worker.perform
        expect(PgHero).to have_received(:capture_query_stats)
      end
    end

    context "when PG_HERO_CAPTURE_QUERY_STATS is set to a value other than 'true'" do
      before { stub_const("ENV", ENV.to_h.merge("PG_HERO_CAPTURE_QUERY_STATS" => "false")) }

      it "does not capture query stats" do
        allow(PgHero).to receive(:capture_query_stats)
        worker.perform
        expect(PgHero).not_to have_received(:capture_query_stats)
      end
    end
  end
end
