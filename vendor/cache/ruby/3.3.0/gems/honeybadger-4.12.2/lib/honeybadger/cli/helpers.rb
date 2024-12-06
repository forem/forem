module Honeybadger
  module CLI
    module Helpers
      module BackendCmd
        def error_message(response)
          host = config.get(:'connection.host')
          <<-MSG
!! --- Honeybadger request failed --------------------------------------------- !!

We encountered an error when contacting the server:

  #{response.error_message}

To fix this issue, please try the following:

  - Make sure the gem is configured properly.
  - Retry executing this command a few times.
  - Make sure you can connect to #{host} (`curl https://#{host}/v1/notices`).
  - Email support@honeybadger.io for help. Include as much debug info as you
    can for a faster resolution!

!! --- End -------------------------------------------------------------------- !!
MSG
        end
      end
    end
  end
end
