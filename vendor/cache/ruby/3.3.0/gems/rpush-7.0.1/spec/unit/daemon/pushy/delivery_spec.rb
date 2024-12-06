require 'unit_spec_helper'

describe Rpush::Daemon::Pushy::Delivery do
  let(:app) { Rpush::Pushy::App.create!(name: 'MyApp', api_key: 'my_api_key') }
  let(:token) { 'device token' }
  let(:data) { { message: 'some message' } }
  let(:notification) { Rpush::Pushy::Notification.create!(app: app, registration_ids: [token], data: data) }
  let(:batch) { instance_double('Rpush::Daemon::Batch', notification_processed: nil) }
  let(:response) { instance_double('Net::HTTPResponse', code: response_code, header: response_header) }
  let(:response_code) { 200 }
  let(:response_header) { {} }
  let(:http) { instance_double('Net::HTTP::Persistent', request: response) }
  let(:logger) { instance_double('Rpush::Logger', error: nil, info: nil, warn: nil, internal_logger: nil) }
  let(:now) { Time.parse('2018-01-19 00:00:00 UTC') }

  before do
    allow(Rpush).to receive_messages(logger: logger)
    allow(Time).to receive_messages(now: now)
  end

  subject(:delivery) { described_class.new(app, http, notification, batch) }

  describe '#pushy_uri' do
    it { expect(subject.pushy_uri).to eq URI.parse('https://api.pushy.me/push?api_key=my_api_key') }
  end

  describe '#perform' do
    shared_examples 'process notification' do
      it 'invoke batch.notification_processed' do
        subject.perform rescue nil
        expect(batch).to have_received(:notification_processed)
      end
    end

    context 'when response code is 200' do
      let(:external_device_id) { '5a60ca7f6ad08477b5070dd3' }

      before do
        allow(batch).to receive(:mark_delivered)
        response_body = {
          success: true,
          id: external_device_id
        }
        allow(response).to receive(:body) { response_body.to_json }
        Rpush::Daemon.store = Rpush::Daemon::Store.const_get(Rpush.config.client.to_s.camelcase).new
      end

      it 'marks the notification as delivered' do
        delivery.perform
        expect(batch).to have_received(:mark_delivered).with(notification)
      end

      it { expect { delivery.perform }.to change { notification.external_device_id }.to(external_device_id) }

      it 'logs than notification received an external id' do
        delivery.perform
        expected = "#{notification.id} received an external id=5a60ca7f6ad08477b5070dd3"
        expect(logger).to have_received(:info).with(expected)
      end

      it_behaves_like 'process notification'
    end

    shared_examples 'retry delivery' do |options|
      let(:response_code) { options[:response_code] }

      shared_examples 'logs' do |log_options|
        let(:deliver_after) { log_options[:deliver_after] }

        let(:expected_log_message) do
          "Pushy responded with a #{response_code} error. Notification #{notification.id} " \
          "will be retried after #{deliver_after} (retry 1)."
        end

        it 'logs that the notification will be retried' do
          delivery.perform
          expect(logger).to have_received(:warn).with(expected_log_message)
        end
      end

      context 'when Retry-After header is present' do
        let(:response_header) { { 'retry-after' => 10 } }

        before do
          allow(delivery).to receive(:mark_retryable) do
            notification.deliver_after = now + 10.seconds
            notification.retries += 1
          end
        end

        it 'retry the notification' do
          delivery.perform
          expect(delivery).to have_received(:mark_retryable).with(notification, now + 10.seconds)
        end

        it_behaves_like 'logs', deliver_after: '2018-01-19 00:00:10'
        it_behaves_like 'process notification'
      end

      context 'when Retry-After header is not present' do
        before do
          allow(delivery).to receive(:mark_retryable_exponential) do
            notification.deliver_after = now + 2.seconds
            notification.retries = 1
          end
        end

        it 'retry the notification' do
          delivery.perform
          expect(delivery).to have_received(:mark_retryable_exponential).with(notification)
        end

        it_behaves_like 'logs', deliver_after: '2018-01-19 00:00:02'
        it_behaves_like 'process notification'
      end
    end

    it_behaves_like 'retry delivery', response_code: 429
    it_behaves_like 'retry delivery', response_code: 500
    it_behaves_like 'retry delivery', response_code: 502
    it_behaves_like 'retry delivery', response_code: 503
    it_behaves_like 'retry delivery', response_code: 504

    context 'when delivery failed' do
      let(:response_code) { 400 }
      let(:fail_message) { 'No devices matched the specified condition.' }
      before do
        allow(response).to receive(:body) { { error: fail_message }.to_json }
        allow(batch).to receive(:mark_failed)
      end

      it 'logs that the notifications failed' do
        expect { delivery.perform }.to raise_error(Rpush::DeliveryError)
        expect(logger).to have_received(:error).with("#{notification.id} failed: #{fail_message}")
      end

      it 'marks the notification as failed' do
        expect { delivery.perform }.to raise_error(Rpush::DeliveryError)
        expected_message = "Unable to deliver notification #{notification.id}, " \
                           "received error 400 (#{fail_message})"
        expect(batch).to have_received(:mark_failed).with(notification, 400, expected_message)
      end

      it_behaves_like 'process notification'
    end

    context 'when SocketError raised' do
      before do
        allow(http).to receive(:request) { raise SocketError }
        allow(delivery).to receive(:mark_retryable)
      end

      it 'retry delivery after 10 seconds' do
        expect { delivery.perform }.to raise_error(SocketError)
        expect(delivery).to have_received(:mark_retryable).with(notification, now + 10.seconds, SocketError)
      end

      it_behaves_like 'process notification'
    end
  end
end
