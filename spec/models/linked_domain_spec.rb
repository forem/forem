require "rails_helper"

RSpec.describe LinkedDomain, type: :model do
  describe "validations" do
    subject { LinkedDomain.new(host: "example.com") }

    before { LinkedDomain.create!(host: "example.com") }

    it { is_expected.to validate_presence_of(:host) }
    it { is_expected.to validate_uniqueness_of(:host) }
  end

  describe "enums" do
    it "defines manual_setting enum" do
      expect(subject).to define_enum_for(:manual_setting)
        .with_values(
          not_set: 0,
          ignored: 1,
          basic_spam: 2,
          extreme_spam: 3
        )
    end
  end

  describe "manual_setting limits on net_score" do
    let(:domain) { LinkedDomain.create!(host: "example.com") }

    context "when ignored is set" do
      before { domain.update(manual_setting: :ignored) }

      it "forces net_score to be 0 even if updated to positive" do
        domain.update(net_score: 500)
        expect(domain.reload.net_score).to eq(0)
      end

      it "forces net_score to be 0 even if updated to negative" do
        domain.update(net_score: -500)
        expect(domain.reload.net_score).to eq(0)
      end
    end

    context "when basic_spam is set" do
      before { domain.update(manual_setting: :basic_spam) }

      it "forces net_score to -2000 if it is set to a higher value" do
        domain.update(net_score: -100)
        expect(domain.reload.net_score).to eq(-2000)
      end

      it "forces net_score to -2000 if it is set to 0" do
        domain.update(net_score: 0)
        expect(domain.reload.net_score).to eq(-2000)
      end

      it "allows net_score to remain lower than -2000" do
        domain.update(net_score: -3000)
        expect(domain.reload.net_score).to eq(-3000)
      end
    end

    context "when extreme_spam is set" do
      before { domain.update(manual_setting: :extreme_spam) }

      it "forces net_score to -10000 if it is set to a higher value" do
        domain.update(net_score: -5000)
        expect(domain.reload.net_score).to eq(-10000)
      end

      it "forces net_score to -10000 if it is set to 0" do
        domain.update(net_score: 0)
        expect(domain.reload.net_score).to eq(-10000)
      end

      it "allows net_score to remain lower than -10000" do
        domain.update(net_score: -15000)
        expect(domain.reload.net_score).to eq(-15000)
      end
    end

    context "when not_set is set" do
      before { domain.update(manual_setting: :not_set) }

      it "allows any net_score" do
        domain.update(net_score: 500)
        expect(domain.reload.net_score).to eq(500)

        domain.update(net_score: -500)
        expect(domain.reload.net_score).to eq(-500)
      end
    end
  end
end
