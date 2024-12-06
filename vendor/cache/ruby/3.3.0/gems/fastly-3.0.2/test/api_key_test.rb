require 'helper'

# API Key Tests
class Fastly
  describe 'ApiKeyTest' do
    let(:opts)             { login_opts(:api_key) }
    let(:client)           { Client.new(opts) }
    let(:fastly)           { Fastly.new(opts) }

    describe '#current_{user,customer}' do
      it 'should not have access to current user 'do
        assert_raises(Error) do
          client.get('/current_user')
        end

        assert_raises(FullAuthRequired) do
          fastly.current_user
        end
      end

      it 'should have access to current customer' do
        assert_instance_of Hash, client.get('/current_customer')
        assert_instance_of Customer, fastly.current_customer
      end

      describe 'purging' do
        describe 'with only api key' do
          before do
            @opts = login_opts(:api_key)
            @client = Fastly::Client.new(@opts)
            @fastly = Fastly.new(@opts)
            service_name = "fastly-test-service-#{random_string}"
            @service      = @fastly.create_service(:name => service_name)
          end

          after do
            @fastly.delete_service(@service)
          end

          it 'allows purging' do
            response = @service.purge_by_key('somekey')

            assert_equal 'ok', response['status']
          end

          it 'allows soft purging' do
            response = @service.purge_by_key('somekey', soft: true)

            assert_equal 'ok', response['status']
          end
        end

        describe 'with username/password and api key' do
          before do
            @opts = login_opts(:both)
            @client = Fastly::Client.new(@opts)
            @fastly = Fastly.new(@opts)
            service_name = "fastly-test-service-#{random_string}"
            @service      = @fastly.create_service(:name => service_name)
          end

          after do
            @fastly.delete_service(@service)
          end

          it 'allows purging' do
            response = @service.purge_by_key('somekey')

            assert_equal 'ok', response['status']
          end

          it 'allows soft purging' do
            response = @service.purge_by_key('somekey', soft: true)

            assert_equal 'ok', response['status']
          end
        end
      end
    end
  end
end
