module Fog
  module Parsers
    module Redshift
      module AWS
        class DescribeReservedNodeOfferings < Fog::Parsers::Base
          # :marker - (String)
          # :reserved_node_offerings - (Array)
          #   :reserved_node_offering_id - (String)
          #   :node_type - (String)
          #   :duration - (Integer)
          #   :fixed_price - (Numeric)
          #   :usage_price - (Numeric)
          #   :currency_code - (String)
          #   :offering_type - (String)
          #   :recurring_charges - (Array)
          #     :recurring_charge_amount - (Numeric)
          #     :recurring_charge_frequency - (String)
          def reset
            @response = { 'ReservedNodeOfferings' => [] }
          end

          def fresh_reserved_node_offering
           {'RecurringCharges' => []}
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'ReservedNodeOfferings'
              @reserved_node_offering = fresh_reserved_node_offering
            when 'RecurringCharges'
              @recurring_charge = {}
            end
          end

          def end_element(name)
            super
            case name
            when 'Marker'
              @response[name] = value
            when 'Duration'
              @reserved_node_offering[name] = value.to_i
            when 'FixedPrice', 'UsagePrice'
              @reserved_node_offering[name] = value.to_f
            when 'CurrencyCode', 'OfferingType', 'NodeType', 'ReservedNodeOfferingId'
              @reserved_node_offering[name] = value
            when 'RecurringChargeAmount'
              @recurring_charge[name] = value.to_f
            when 'RecurringChargeFrequency'
              @recurring_charge[name] = value
            when 'RecurringCharge'
              @reserved_node_offering['RecurringCharges'] << {name => @recurring_charge}
              @recurring_charge = {}
            when 'ReservedNodeOffering'
              @response['ReservedNodeOfferings'] << {name => @reserved_node_offering}
              @reserved_node_offering = fresh_reserved_node_offering
            end
          end
        end
      end
    end
  end
end
