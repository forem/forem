module StripeMock

  def self.mock_webhook_payload(type, params = {})

    fixture_file = File.join(@webhook_fixture_path, "#{type}.json")

    unless File.exists?(fixture_file)
      unless Webhooks.event_list.include?(type)
        raise UnsupportedRequestError.new "Unsupported webhook event `#{type}` (Searched in #{@webhook_fixture_path})"
      end
      fixture_file = File.join(@webhook_fixture_fallback_path, "#{type}.json")
    end

    json = MultiJson.load  File.read(fixture_file)

    json = Stripe::Util.symbolize_names(json)
    params = Stripe::Util.symbolize_names(params)
    json[:account] = params.delete(:account) if params.key?(:account)
    json[:data][:object] = Util.rmerge(json[:data][:object], params)
    json.delete(:id)
    json[:created] = params[:created] || Time.now.to_i

    if @state == 'local'
      event_data = instance.generate_webhook_event(json)
    elsif @state == 'remote'
      event_data = client.generate_webhook_event(json)
    else
      raise UnstartedStateError
    end
    event_data
  end

  def self.mock_webhook_event(type, params={})
    Stripe::Event.construct_from(mock_webhook_payload(type, params))
  end

  module Webhooks
    def self.event_list
      @__list = [
        'account.updated',
        'account.application.deauthorized',
        'account.external_account.created',
        'account.external_account.updated',
        'account.external_account.deleted',
        'balance.available',
        'charge.succeeded',
        'charge.updated',
        'charge.failed',
        'charge.refunded',
        'charge.dispute.created',
        'charge.dispute.updated',
        'charge.dispute.closed',
        'charge.dispute.funds_reinstated',
        'charge.dispute.funds_withdrawn',
        'customer.source.created',
        'customer.source.deleted',
        'customer.source.updated',
        'customer.created',
        'customer.updated',
        'customer.deleted',
        'customer.subscription.created',
        'customer.subscription.updated',
        'customer.subscription.deleted',
        'customer.subscription.trial_will_end',
        'customer.discount.created',
        'customer.discount.updated',
        'customer.discount.deleted',
        'invoice.created',
        'invoice.updated',
        'invoice.payment_succeeded',
        'invoice.payment_failed',
        'invoiceitem.created',
        'invoiceitem.updated',
        'invoiceitem.deleted',
        'payment_intent.succeeded',
        'payment_intent.payment_failed',
        'plan.created',
        'plan.updated',
        'plan.deleted',
        'product.created',
        'product.updated',
        'product.deleted',
        'coupon.created',
        'coupon.deleted',
        'transfer.created',
        'transfer.paid',
        'transfer.updated',
        'transfer.failed'
      ]
    end
  end

end
