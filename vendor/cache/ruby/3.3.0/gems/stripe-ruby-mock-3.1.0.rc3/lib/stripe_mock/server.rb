require 'drb/drb'

module StripeMock
  class Server
    def self.start_new(opts)
      puts "Starting StripeMock server on port #{opts[:port] || 4999}"

      host = opts.fetch :host,'0.0.0.0'
      port = opts.fetch :port, 4999

      DRb.start_service "druby://#{host}:#{port}", Server.new
      DRb.thread.join
    end

    def initialize
      self.clear_data
    end

    def mock_request(*args, **kwargs)
      begin
        @instance.mock_request(*args, **kwargs)
      rescue Stripe::InvalidRequestError => e
        {
          :error_raised => 'invalid_request',
          :error_params => [
            e.message, e.param, { http_status: e.http_status, http_body: e.http_body, json_body: e.json_body}
          ]
        }
      end
    end

    def get_data(key)
      @instance.send(key)
    end

    def destroy_resource(type, id)
      @instance.send(type).delete(id)
    end

    def clear_data
      @instance = Instance.new
    end

    def set_debug(toggle)
      @instance.debug = toggle
    end

    def set_global_id_prefix(value)
      StripeMock.global_id_prefix = value
    end

    def global_id_prefix
      StripeMock.global_id_prefix
    end

    def generate_card_token(card_params)
      @instance.generate_card_token(card_params)
    end

    def generate_bank_token(recipient_params)
      @instance.generate_bank_token(recipient_params)
    end

    def generate_webhook_event(event_data)
      @instance.generate_webhook_event(event_data)
    end

    def set_conversion_rate(value)
      @instance.conversion_rate = value
    end

    def set_account_balance(value)
      @instance.account_balance = value
    end

    def error_queue
      @instance.error_queue
    end

    def debug?
      @instance.debug
    end

    def ping
      true
    end

    def upsert_stripe_object(object, attributes)
      @instance.upsert_stripe_object(object, attributes)
    end

  end
end
