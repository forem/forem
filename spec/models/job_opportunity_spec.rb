require "rails_helper"

RSpec.describe JobOpportunity, type: :model do
  let(:job_opportunity) { described_class.new(remoteness: "on_premise") }

  context "when validations" do
    describe "#remoteness" do
      it "is valid with on_premise" do
        job_opportunity.remoteness = "on_premise"
        expect(job_opportunity).to be_valid
      end

      it "is valid with fully_remote" do
        job_opportunity.remoteness = "fully_remote"
        expect(job_opportunity).to be_valid
      end

      it "is valid with remote_optional" do
        job_opportunity.remoteness = "remote_optional"
        expect(job_opportunity).to be_valid
      end

      it "is valid with on_premise_flexible" do
        job_opportunity.remoteness = "on_premise_flexible"
        expect(job_opportunity).to be_valid
      end

      it "is not valid an arbitrary word" do
        job_opportunity.remoteness = "foobar"
        expect(job_opportunity).not_to be_valid
      end
    end
  end

  describe "#remoteness_in_words" do
    it "returns remoteness in words for on_premise" do
      job_opportunity.remoteness = "on_premise"
      expect(job_opportunity.remoteness_in_words).to eq("In Office")
    end

    it "returns remoteness in words for fully_remote" do
      job_opportunity.remoteness = "fully_remote"
      expect(job_opportunity.remoteness_in_words).to eq("Fully Remote")
    end

    it "returns remoteness in words for remote_optional" do
      job_opportunity.remoteness = "remote_optional"
      expect(job_opportunity.remoteness_in_words).to eq("Remote Optional")
    end

    it "returns remoteness in words for on_premise_flexible" do
      job_opportunity.remoteness = "on_premise_flexible"
      expect(job_opportunity.remoteness_in_words).to eq("Mostly in Office but Flexible")
    end
  end
end
