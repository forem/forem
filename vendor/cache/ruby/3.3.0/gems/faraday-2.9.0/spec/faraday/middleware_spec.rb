# frozen_string_literal: true

RSpec.describe Faraday::Middleware do
  subject { described_class.new(app) }
  let(:app) { double }

  describe 'options' do
    context 'when options are passed to the middleware' do
      subject { described_class.new(app, options) }
      let(:options) { { field: 'value' } }

      it 'accepts options when initialized' do
        expect(subject.options[:field]).to eq('value')
      end
    end
  end

  describe '#on_request' do
    subject do
      Class.new(described_class) do
        def on_request(env)
          # do nothing
        end
      end.new(app)
    end

    it 'is called by #call' do
      expect(app).to receive(:call).and_return(app)
      expect(app).to receive(:on_complete)
      is_expected.to receive(:call).and_call_original
      is_expected.to receive(:on_request)
      subject.call(double)
    end
  end

  describe '#on_error' do
    subject do
      Class.new(described_class) do
        def on_error(error)
          # do nothing
        end
      end.new(app)
    end

    it 'is called by #call' do
      expect(app).to receive(:call).and_raise(Faraday::ConnectionFailed)
      is_expected.to receive(:call).and_call_original
      is_expected.to receive(:on_error)

      expect { subject.call(double) }.to raise_error(Faraday::ConnectionFailed)
    end
  end

  describe '#close' do
    context "with app that doesn't support \#close" do
      it 'should issue warning' do
        is_expected.to receive(:warn)
        subject.close
      end
    end

    context "with app that supports \#close" do
      it 'should issue warning' do
        expect(app).to receive(:close)
        is_expected.to_not receive(:warn)
        subject.close
      end
    end
  end
end
