require 'spec_helper'

require 'database_cleaner'
DatabaseCleaner.strategy = :truncation

def functional_example?(metadata)
  metadata[:file_path] =~ %r{/spec/functional/}
end

def timeout(&blk)
  Timeout.timeout(10, &blk)
end

def stub_tcp_connection(tcp_socket, ssl_socket, io_double)
  allow_any_instance_of(Rpush::Daemon::TcpConnection).to receive_messages(connect_socket: [tcp_socket, ssl_socket])
  allow_any_instance_of(Rpush::Daemon::TcpConnection).to receive_messages(setup_ssl_context: double.as_null_object)
  stub_const('Rpush::Daemon::TcpConnection::IO', io_double)
end

RSpec.configure do |config|
  config.before(:each) do
    Modis.with_connection do |redis|
      redis.keys('rpush:*').each { |key| redis.del(key) }
    end if redis?

    Rpush.config.logger = ::Logger.new(STDOUT) if functional_example?(self.class.metadata)
  end

  config.after(:each) do
    DatabaseCleaner.clean if active_record? && functional_example?(self.class.metadata)
  end
end
