require 'spec_helper'

describe FakeRedis do
  after { described_class.disable }

  describe '.enable' do
    it 'in memory connection' do
      described_class.enable
      expect(described_class.enabled?).to be_truthy
    end
  end

  describe '.disable' do
    before { described_class.enable }

    it 'in memory connection' do
      described_class.disable
      expect(described_class.enabled?).to be_falsy
    end
  end

  describe '.disabling' do
    context 'FakeRedis is enabled' do
      before { described_class.enable }

      it 'in memory connection' do
        described_class.disabling do
          expect(described_class.enabled?).to be_falsy
        end

        expect(described_class.enabled?).to be_truthy
      end
    end

    context 'FakeRedis is disabled' do
      before { described_class.disable }

      it 'in memory connection' do
        described_class.disabling do
          expect(described_class.enabled?).to be_falsy
        end

        expect(described_class.enabled?).to be_falsy
      end
    end
  end

  describe '.enabling' do
    context 'FakeRedis is enabled' do
      before { described_class.enable }

      it 'in memory connection' do
        described_class.enabling do
          expect(described_class.enabled?).to be_truthy
        end

        expect(described_class.enabled?).to be_truthy
      end
    end

    context 'FakeRedis is disabled' do
      before { described_class.disable }

      it 'in memory connection' do
        described_class.enabling do
          expect(described_class.enabled?).to be_truthy
        end

        expect(described_class.enabled?).to be_falsy
      end
    end
  end
end
