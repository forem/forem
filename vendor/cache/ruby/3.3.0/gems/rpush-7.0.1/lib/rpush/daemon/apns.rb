module Rpush
  module Daemon
    module Apns
      extend ServiceConfigMethods

      HOSTS = {
        production: ['gateway.push.apple.com', 2195],
        development: ['gateway.sandbox.push.apple.com', 2195], # deprecated
        sandbox: ['gateway.sandbox.push.apple.com', 2195]
      }

      batch_deliveries true
      dispatcher :apns_tcp, host: proc { |app| HOSTS[app.environment.to_sym] }
      loops Rpush::Daemon::Apns::FeedbackReceiver, if: -> { Rpush.config.apns.feedback_receiver.enabled && !Rpush.config.push }
    end
  end
end
