module Fog
  module Parsers
    module Redshift
      module AWS
        class DescribeReservedNodes < Fog::Parsers::Base
          # :marker - (String)
          # :reserved_nodes - (Array)
          #   :reserved_node_id - (String)
          #   :reserved_node_offering_id - (String)
          #   :node_type - (String)
          #   :start_time - (Time)
          #   :duration - (Integer)
          #   :fixed_price - (Numeric)
          #   :usage_price - (Numeric)
          #   :currency_code - (String)
          #   :node_count - (Integer)
          #   :state - (String)
          #   :offering_type - (String)
          #   :recurring_charges - (Array)
          #     :recurring_charge_amount - (Numeric)
          #     :recurring_charge_frequency - (String)

          def reset
            @response = { 'ReservedNodes' => [] }
          end

          def fresh_reserved_nodes
           {'RecurringCharges' => []}
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'ReservedNodes'
              @reserved_node = fresh_reserved_nodes
            when 'RecurringCharges'
              @recurring_charge = {}
            end
          end

          def end_element(name)
            super
            case name
            when 'Marker'
              @response[name] = value
            when 'Duration', 'NodeCount'
              @reserved_node[name] = value.to_i
            when 'StartTime'
              @reserved_node[name] = Time.parse(value)
            when 'FixedPrice', 'UsagePrice'
              @reserved_node[name] = value.to_f
            when 'CurrencyCode', 'OfferingType', 'NodeType', 'ReservedNodeOfferingId', 'ReservedNodeId', 'State'
              @reserved_node[name] = value
            when 'RecurringChargeAmount'
              @recurring_charge[name] = value.to_f
            when 'RecurringChargeFrequency'
              @recurring_charge[name] = value
            when 'RecurringCharge'
              @reserved_node['RecurringCharges'] << {name => @recurring_charge}
              @recurring_charge = {}
            when 'ReservedNode'
              @response['ReservedNodes'] << {name => @reserved_node}
              @reserved_node = fresh_reserved_nodes
            end
          end
        end
      end
    end
  end
end
