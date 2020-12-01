RSpec.describe "be_new_record" do
  context "a new record" do
    let(:record) { double('record', new_record?: true) }

    it "passes" do
      expect(record).to be_new_record
    end

    it "fails with custom failure message" do
      expect {
        expect(record).not_to be_new_record
      }.to raise_exception(/expected .* to be persisted, but was a new record/)
    end
  end

  context "a persisted record" do
    let(:record) { double('record', new_record?: false) }

    it "fails" do
      expect(record).not_to be_new_record
    end

    it "fails with custom failure message" do
      expect {
        expect(record).to be_new_record
      }.to raise_exception(/expected .* to be a new record, but was persisted/)
    end
  end
end
