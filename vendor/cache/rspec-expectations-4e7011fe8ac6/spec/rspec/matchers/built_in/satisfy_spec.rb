RSpec.describe "expect(...).to satisfy { block }" do
  it_behaves_like "an RSpec value matcher", :valid_value => true, :invalid_value => false do
    let(:matcher) { satisfy { |v| v } }
  end

  it "describes itself" do
    expect(satisfy.description).to eq("satisfy block")
  end

  it "passes if block returns true" do
    expect(true).to satisfy { |val| val }
    expect(true).to satisfy do |val|
      val
    end
  end

  context "when no custom description is provided" do
    context 'in Ripper supported environment', :if => RSpec::Support::RubyFeatures.ripper_supported? do
      it "fails with block snippet if block returns false" do
        expect {
          expect(false).to satisfy { |val| val }
        }.to fail_with("expected false to satisfy expression `val`")

        expect do
          expect(false).to satisfy do |val|
            val
          end
        end.to fail_with("expected false to satisfy expression `val`")
      end

      context 'when used with an alias name' do
        alias_matcher :fulfill, :satisfy

        it 'can extract the block snippet' do
          expect {
            expect(false).to fulfill { |val| val }
          }.to fail_with("expected false to fulfill expression `val`")
        end
      end
    end

    context 'in Ripper unsupported environment', :unless => RSpec::Support::RubyFeatures.ripper_supported? do
      it "fails without block snippet if block returns false" do
        expect {
          expect(false).to satisfy { |val| val }
        }.to fail_with("expected false to satisfy block")

        expect do
          expect(false).to satisfy do |val|
            val
          end
        end.to fail_with("expected false to satisfy block")
      end
    end
  end

  context "when a custom description is provided" do
    it "describes itself" do
      expect(satisfy("be awesome").description).to eq("be awesome")
    end

    it "passes if block returns true" do
      expect(true).to satisfy("be true") { |val| val }
      expect(true).to satisfy("be true") do |val|
        val
      end
    end

    it "fails with the custom description if block returns false" do
      expect {
        expect(false).to satisfy("be true") { |val| val }
      }.to fail_with("expected false to be true")
      expect do
        expect(false).to satisfy("be true") do |val|
          val
        end
      end.to fail_with("expected false to be true")
    end
  end
end

RSpec.describe "expect(...).not_to satisfy { block }" do
  it "passes if block returns false" do
    expect(false).not_to satisfy { |val| val }
    expect(false).not_to satisfy do |val|
      val
    end
  end

  context "when no custom description is provided" do
    context 'in Ripper supported environment', :if => RSpec::Support::RubyFeatures.ripper_supported? do
      it "fails with block snippet if block returns true" do
        expect {
          expect(true).not_to satisfy { |val| val }
        }.to fail_with("expected true not to satisfy expression `val`")
      end
    end

    context 'in Ripper unsupported environment', :unless => RSpec::Support::RubyFeatures.ripper_supported? do
      it "fails without block snippet if block returns true" do
        expect {
          expect(true).not_to satisfy { |val| val }
        }.to fail_with("expected true not to satisfy block")
      end
    end
  end

  context "when a custom description is provided" do
    it "passes if block returns false" do
      expect(false).not_to satisfy("be true") { |val| val }
      expect(false).not_to satisfy("be true") do |val|
        val
      end
    end

    it "fails with the custom description if block returns true" do
      expect {
        expect(true).not_to satisfy("be true") { |val| val }
      }.to fail_with("expected true not to be true")
    end
  end
end
