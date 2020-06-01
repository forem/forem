# monkeypatch
module Warden
  def self.test_mode!
    Rails.logger.error('in test mode!')
    unless Warden::Test::WardenHelpers === Warden
      Warden.extend Warden::Test::WardenHelpers
      Warden::Manager.on_request do |proxy|
        Rails.logger.error('in on request')
        unless proxy.asset_request?
          while blk = Warden._on_next_request.shift
            Rails.logger.error("in on request: #{blk}")
            blk.call(proxy)
          end
        end
      end
    end
    true
  end
end
