# frozen_string_literal: true

require 'spec_helper'

module Bullet
  describe Rack do
    let(:middleware) { Bullet::Rack.new app }
    let(:app) { Support::AppDouble.new }

    context '#html_request?' do
      it 'should be true if Content-Type is text/html and http body contains html tag' do
        headers = { 'Content-Type' => 'text/html' }
        response = double(body: '<html><head></head><body></body></html>')
        expect(middleware).to be_html_request(headers, response)
      end

      it 'should be true if Content-Type is text/html and http body contains html tag with attributes' do
        headers = { 'Content-Type' => 'text/html' }
        response = double(body: "<html attr='hello'><head></head><body></body></html>")
        expect(middleware).to be_html_request(headers, response)
      end

      it 'should be false if there is no Content-Type header' do
        headers = {}
        response = double(body: '<html><head></head><body></body></html>')
        expect(middleware).not_to be_html_request(headers, response)
      end

      it 'should be false if Content-Type is javascript' do
        headers = { 'Content-Type' => 'text/javascript' }
        response = double(body: '<html><head></head><body></body></html>')
        expect(middleware).not_to be_html_request(headers, response)
      end

      it "should be false if response body doesn't contain html tag" do
        headers = { 'Content-Type' => 'text/html' }
        response = double(body: '<div>Partial</div>')
        expect(middleware).not_to be_html_request(headers, response)
      end
    end

    context 'empty?' do
      it 'should be false if response is a string and not empty' do
        response = double(body: '<html><head></head><body></body></html>')
        expect(middleware).not_to be_empty(response)
      end

      it 'should be false if response is not found' do
        response = ['Not Found']
        expect(middleware).not_to be_empty(response)
      end

      it 'should be true if response body is empty' do
        response = double(body: '')
        expect(middleware).to be_empty(response)
      end
    end

    context '#call' do
      context 'when Bullet is enabled' do
        it 'should return original response body' do
          expected_response = Support::ResponseDouble.new 'Actual body'
          app.response = expected_response
          _, _, response = middleware.call({})
          expect(response).to eq(expected_response)
        end

        it 'should change response body if notification is active' do
          expect(Bullet).to receive(:notification?).and_return(true)
          expect(Bullet).to receive(:console_enabled?).and_return(true)
          expect(Bullet).to receive(:gather_inline_notifications).and_return('<bullet></bullet>')
          expect(Bullet).to receive(:perform_out_of_channel_notifications)
          _, headers, response = middleware.call('Content-Type' => 'text/html')
          expect(headers['Content-Length']).to eq('56')
          expect(response).to eq(%w[<html><head></head><body><bullet></bullet></body></html>])
        end

        it 'should set the right Content-Length if response body contains accents' do
          response = Support::ResponseDouble.new
          response.body = '<html><head></head><body>é</body></html>'
          app.response = response
          expect(Bullet).to receive(:notification?).and_return(true)
          allow(Bullet).to receive(:console_enabled?).and_return(true)
          expect(Bullet).to receive(:gather_inline_notifications).and_return('<bullet></bullet>')
          _, headers, response = middleware.call('Content-Type' => 'text/html')
          expect(headers['Content-Length']).to eq('58')
        end

        context 'with injection notifiers' do
          before do
            expect(Bullet).to receive(:notification?).and_return(true)
            allow(Bullet).to receive(:gather_inline_notifications).and_return('<bullet></bullet>')
            allow(middleware).to receive(:xhr_script).and_return('')
            allow(middleware).to receive(:footer_note).and_return('footer')
            expect(Bullet).to receive(:perform_out_of_channel_notifications)
          end

          it 'should change response body if add_footer is true' do
            expect(Bullet).to receive(:add_footer).exactly(3).times.and_return(true)
            _, headers, response = middleware.call('Content-Type' => 'text/html')

            expect(headers['Content-Length']).to eq((56 + middleware.send(:footer_note).length).to_s)
            expect(response.first).to start_with('<html><head></head><body>')
            expect(response.first).to include('<bullet></bullet><')
          end

          it 'should change response body for html safe string if add_footer is true' do
            expect(Bullet).to receive(:add_footer).exactly(3).times.and_return(true)
            app.response = Support::ResponseDouble.new.tap do |response|
              response.body = ActiveSupport::SafeBuffer.new('<html><head></head><body></body></html>')
            end
            _, headers, response = middleware.call('Content-Type' => 'text/html')

            expect(headers['Content-Length']).to eq((56 + middleware.send(:footer_note).length).to_s)
            expect(response.first).to start_with('<html><head></head><body>')
            expect(response.first).to include('<bullet></bullet><')
          end

          it 'should change response body if console_enabled is true' do
            expect(Bullet).to receive(:console_enabled?).and_return(true)
            _, headers, response = middleware.call('Content-Type' => 'text/html')
            expect(headers['Content-Length']).to eq('56')
            expect(response).to eq(%w[<html><head></head><body><bullet></bullet></body></html>])
          end

          it 'should change response body for html safe string if console_enabled is true' do
            expect(Bullet).to receive(:console_enabled?).and_return(true)
            app.response = Support::ResponseDouble.new.tap do |response|
              response.body = ActiveSupport::SafeBuffer.new('<html><head></head><body></body></html>')
            end
            _, headers, response = middleware.call('Content-Type' => 'text/html')
            expect(headers['Content-Length']).to eq('56')
            expect(response).to eq(%w[<html><head></head><body><bullet></bullet></body></html>])
          end

          it "shouldn't change response body unnecessarily" do
            expected_response = Support::ResponseDouble.new 'Actual body'
            app.response = expected_response
            _, _, response = middleware.call({})
            expect(response).to eq(expected_response)
          end
        end

        context 'when skip_html_injection is enabled' do
          it 'should not try to inject html' do
            expected_response = Support::ResponseDouble.new 'Actual body'
            app.response = expected_response
            allow(Bullet).to receive(:notification?).and_return(true)
            allow(Bullet).to receive(:skip_html_injection?).and_return(true)
            expect(Bullet).to receive(:gather_inline_notifications).never
            expect(middleware).to receive(:xhr_script).never
            expect(Bullet).to receive(:perform_out_of_channel_notifications)
            _, _, response = middleware.call('Content-Type' => 'text/html')
            expect(response).to eq(expected_response)
          end
        end
      end

      context 'when Bullet is disabled' do
        before(:each) { allow(Bullet).to receive(:enable?).and_return(false) }

        it 'should not call Bullet.start_request' do
          expect(Bullet).not_to receive(:start_request)
          middleware.call({})
        end
      end
    end

    context '#set_header' do
      it 'should truncate headers to under 8kb' do
        long_header = ['a' * 1_024] * 10
        expected_res = (['a' * 1_024] * 7).to_json
        expect(middleware.set_header({}, 'Dummy-Header', long_header)).to eq(expected_res)
      end
    end

    describe '#response_body' do
      let(:response) { double }
      let(:body_string) { '<html><body>My Body</body></html>' }

      context 'when `response` responds to `body`' do
        before { allow(response).to receive(:body).and_return(body) }

        context 'when `body` returns an Array' do
          let(:body) { [body_string, 'random string'] }
          it 'should return the plain body string' do
            expect(middleware.response_body(response)).to eq body_string
          end
        end

        context 'when `body` does not return an Array' do
          let(:body) { body_string }
          it 'should return the plain body string' do
            expect(middleware.response_body(response)).to eq body_string
          end
        end
      end

      context 'when `response` does not respond to `body`' do
        before { allow(response).to receive(:first).and_return(body_string) }

        it 'should return the plain body string' do
          expect(middleware.response_body(response)).to eq body_string
        end
      end
    end
  end
end
