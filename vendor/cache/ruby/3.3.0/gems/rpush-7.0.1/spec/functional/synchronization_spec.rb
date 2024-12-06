require 'functional_spec_helper'

describe 'Synchronization' do
  let(:timeout) { 10 }
  let(:app) { Rpush::Gcm::App.new }

  def wait_for_num_dispatchers(num)
    Timeout.timeout(timeout) do
      until Rpush::Daemon::AppRunner.num_dispatchers_for_app(app) == num
        sleep 0.1
      end
    end
  end

  before do
    app.name = 'test'
    app.auth_key = 'abc123'
    app.client_id = 'client'
    app.client_secret = 'secret'
    app.connections = 2
    app.certificate = TEST_CERT_WITH_PASSWORD
    app.password = 'fubar'
    app.environment = 'sandbox'
    app.save!

    Rpush.embed
    wait_for_num_dispatchers(app.connections)
  end

  after { Timeout.timeout(timeout) { Rpush.shutdown } }

  it 'increments the number of dispatchers' do
    app.connections += 1
    app.save!
    Rpush.sync
    wait_for_num_dispatchers(app.connections)
  end

  it 'decrements the number of dispatchers' do
    app.connections -= 1
    app.save!
    Rpush.sync
    wait_for_num_dispatchers(app.connections)
  end

  it 'stops a deleted app' do
    app.destroy
    Rpush.sync
    expect(Rpush::Daemon::AppRunner.app_running?(app)).to eq(false)
  end

  it 'restarts an app when the certificate is changed' do
    app.certificate = TEST_CERT
    app.password = nil
    app.save!
    Rpush.sync

    running_app = Rpush::Daemon::AppRunner.app_with_id(app.id)
    expect(running_app.certificate).to eql(TEST_CERT)
  end

  it 'restarts an app when the environment is changed' do
    app.environment = 'production'
    app.save!
    Rpush.sync

    running_app = Rpush::Daemon::AppRunner.app_with_id(app.id)
    expect(running_app.environment).to eql('production')
  end

  it 'restarts an app when the auth_key is changed' do
    app.auth_key = '321cba'
    app.save!
    Rpush.sync

    running_app = Rpush::Daemon::AppRunner.app_with_id(app.id)
    expect(running_app.auth_key).to eql('321cba')
  end

  it 'restarts an app when the client_id is changed' do
    app.client_id = 'another_client'
    app.save!
    Rpush.sync

    running_app = Rpush::Daemon::AppRunner.app_with_id(app.id)
    expect(running_app.client_id).to eql('another_client')
  end

  it 'restarts an app when the client_secret is changed' do
    app.client_secret = 'another_secret'
    app.save!
    Rpush.sync

    running_app = Rpush::Daemon::AppRunner.app_with_id(app.id)
    expect(running_app.client_secret).to eql('another_secret')
  end
end
