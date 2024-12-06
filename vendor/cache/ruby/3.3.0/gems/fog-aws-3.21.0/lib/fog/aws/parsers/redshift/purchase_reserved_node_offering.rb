module Fog
  module Parsers
    module Redshift
      module AWS
        class PurchaseReservedNodeOffering < Fog::Parsers::Base
          # :reserved_node_id - (String)
          # :reserved_node_offering_id - (String)
          # :node_type - (String)
          # :start_time - (Time)
          # :duration - (Integer)
          # :fixed_price - (Numeric)
          # :usage_price - (Numeric)
          # :currency_code - (String)
          # :node_count - (Integer)
          # :state - (String)
          # :offering_type - (String)
          # :recurring_charges - (Array)
          #   :recurring_charge_amount - (Numeric)
          #   :recurring_charge_frequency - (String)
          def reset
            @response = { 'RecurringCharges' => [] }
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'RecurringCharges'
              @recurring_charge = {}
            end
          end

          def end_element(name)
            super
            case name
            when 'ReservedNodeId', 'ReservedNodeOfferingId', 'NodeType', 'CurrencyCode', 'State', 'OfferingType'
              @response[name] = value
            when 'Duration', 'NodeCount'
              @response[name] = value.to_i
            when 'FixedPrice', 'UsagePrice'
              @response[name] = value.to_f
            when 'StartTime'
              @response[name] = Time.parse(value)
            when 'RecurringChargeAmount'
              @recurring_charge[name] = value.to_f
            when 'RecurringChargeFrequency'
              @recurring_charge[name] = value
            when 'RecurringCharge'
              @response['RecurringCharges'] << {name => @recurring_charge}
              @recurring_charge = {}
            end
          end
        end
      end
    end
  end
end
