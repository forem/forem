module StripeMock
  module RequestHandlers
    module Helpers

      def get_customer_subscription(customer, sub_id)
        customer[:subscriptions][:data].find{|sub| sub[:id] == sub_id }
      end

      def resolve_subscription_changes(subscription, plans, customer, options = {})
        subscription.merge!(custom_subscription_params(plans, customer, options))
        items = options[:items]
        items = items.values if items.respond_to?(:values)
        subscription[:items][:data] = plans.map do |plan|
          matching_item = items && items.detect { |item| [item[:price], item[:plan]].include? plan[:id] }
          if matching_item
            quantity = matching_item[:quantity] || 1
            id = matching_item[:id] || new_id('si')
            Data.mock_subscription_item({ plan: plan, quantity: quantity, id: id })
          else
            Data.mock_subscription_item({ plan: plan, id: new_id('si') })
          end
        end
        subscription
      end

      def custom_subscription_params(plans, cus, options = {})
        verify_trial_end(options[:trial_end]) if options[:trial_end]

        plan = plans.first if plans.size == 1

        now = Time.now.utc.to_i
        created_time = options[:created] || now
        start_time = options[:current_period_start] || now
        params = { customer: cus[:id], current_period_start: start_time, created: created_time }
        params.merge!({ :plan => (plans.size == 1 ? plans.first : nil) })
        keys_to_merge = /application_fee_percent|quantity|metadata|tax_percent|billing|days_until_due|default_tax_rates|pending_invoice_item_interval|default_payment_method|collection_method/
        params.merge! options.select {|k,v| k =~ keys_to_merge}

        if options[:cancel_at_period_end] == true
          params.merge!(cancel_at_period_end: true, canceled_at: now)
        elsif options[:cancel_at_period_end] == false
          params.merge!(cancel_at_period_end: false, canceled_at: nil)
        end

        # TODO: Implement coupon logic

        if (((plan && plan[:trial_period_days]) || 0) == 0 && options[:trial_end].nil?) || options[:trial_end] == "now"
          end_time = options[:billing_cycle_anchor] || get_ending_time(start_time, plan)
          params.merge!({status: 'active', current_period_end: end_time, trial_start: nil, trial_end: nil, billing_cycle_anchor: options[:billing_cycle_anchor]})
        else
          end_time = options[:trial_end] || (Time.now.utc.to_i + plan[:trial_period_days]*86400)
          params.merge!({status: 'trialing', current_period_end: end_time, trial_start: start_time, trial_end: end_time, billing_cycle_anchor: nil})
        end

        params
      end

      def add_subscription_to_customer(cus, sub)
        if sub[:trial_end].nil? || sub[:trial_end] == "now"
          id = new_id('ch')
          charges[id] = Data.mock_charge(
            :id => id,
            :customer => cus[:id],
            :amount => (sub[:plan] ? sub[:plan][:amount] : total_items_amount(sub[:items][:data]))
          )
        end

        if cus[:currency].nil?
          cus[:currency] = sub[:items][:data][0][:plan][:currency]
        elsif cus[:currency] != sub[:items][:data][0][:plan][:currency]
          raise Stripe::InvalidRequestError.new( "Can't combine currencies on a single customer. This customer has had a subscription, coupon, or invoice item with currency #{cus[:currency]}", 'currency', http_status: 400)
        end
        cus[:subscriptions][:total_count] = (cus[:subscriptions][:total_count] || 0) + 1
        cus[:subscriptions][:data].unshift sub
      end

      def delete_subscription_from_customer(cus, subscription)
        cus[:subscriptions][:data].reject!{|sub|
          sub[:id] == subscription[:id]
        }
        cus[:subscriptions][:total_count] -=1
      end

      # `intervals` is set to 1 when calculating current_period_end from current_period_start & plan
      # `intervals` is set to 2 when calculating Stripe::Invoice.upcoming end from current_period_start & plan
      def get_ending_time(start_time, plan, intervals = 1)
        return start_time unless plan

        case plan[:interval]
        when "week"
          start_time + (604800 * (plan[:interval_count] || 1) * intervals)
        when "month"
          (Time.at(start_time).to_datetime >> ((plan[:interval_count] || 1) * intervals)).to_time.to_i
        when "year"
          (Time.at(start_time).to_datetime >> (12 * intervals)).to_time.to_i # max period is 1 year
        else
          start_time
        end
      end

      def verify_trial_end(trial_end)
        if trial_end != "now"
          if !trial_end.is_a? Integer
            raise Stripe::InvalidRequestError.new('Invalid timestamp: must be an integer', nil, http_status: 400)
          elsif trial_end < Time.now.utc.to_i
            raise Stripe::InvalidRequestError.new('Invalid timestamp: must be an integer Unix timestamp in the future', nil, http_status: 400)
          elsif trial_end > Time.now.utc.to_i + 31557600*5 # five years
            raise Stripe::InvalidRequestError.new('Invalid timestamp: can be no more than five years in the future', nil, http_status: 400)
          end
        end
      end

      def total_items_amount(items)
        total = 0
        items.each do |item|
          quantity = item[:quantity] || 1
          amount = item[:plan][:unit_amount] || item[:plan][:amount]
          total += quantity * amount
        end
        total
      end
    end
  end
end
