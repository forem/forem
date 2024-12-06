module Fog
  module Parsers
    module AWS
      module Compute
        class NetworkAclParser < Fog::Parsers::Base
          def reset_nacl
            @network_acl = { 'associationSet' => [], 'entrySet' => [], 'tagSet' => {} }
            @association = {}
            @entry = { 'icmpTypeCode' => {}, 'portRange' => {} }
            @tag = {}

            @in_entry_set       = false
            @in_association_set = false
            @in_tag_set         = false
            @in_port_range      = false
            @in_icmp_type_code  = false
          end

          def reset
            reset_nacl
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'entrySet'
              @in_entry_set = true
            when 'associationSet'
              @in_association_set = true
            when 'tagSet'
              @in_tag_set = true
            when 'portRange'
              @in_port_range = true
            when 'icmpTypeCode'
              @in_icmp_type_code = true
            end
          end

          def end_element(name)
            if @in_entry_set
              if @in_port_range
                case name
                when 'portRange'
                  @in_port_range = false
                when 'from', 'to'
                  @entry['portRange'][name] = value.to_i
                end
              elsif @in_icmp_type_code
                case name
                when 'icmpTypeCode'
                  @in_icmp_type_code = false
                when 'code', 'type'
                  @entry['icmpTypeCode'][name] = value.to_i
                end
              else
                case name
                when 'entrySet'
                  @in_entry_set = false
                when 'item'
                  @network_acl['entrySet'] << @entry
                  @entry = { 'icmpTypeCode' => {}, 'portRange' => {} }
                when 'ruleNumber', 'protocol'
                  @entry[name] = value.to_i
                when 'ruleAction', 'cidrBlock'
                  @entry[name] = value
                when 'egress'
                  @entry[name] = value == 'true'
                end
              end
            elsif @in_association_set
              case name
              when 'associationSet'
                @in_association_set = false
              when 'item'
                @network_acl['associationSet'] << @association
                @association = {}
              when 'networkAclAssociationId', 'networkAclId', 'subnetId'
                @association[name] = value
              end
            elsif @in_tag_set
              case name
              when 'tagSet'
                @in_tag_set = false
              when 'item'
                @network_acl['tagSet'][@tag['key']] = @tag['value']
                @tag = {}
              when 'key', 'value'
                @tag[name] = value
              end
            else
              case name
              when 'networkAclId', 'vpcId'
                @network_acl[name] = value
              when 'default'
                @network_acl[name] = value == 'true'
              end
            end
          end
        end
      end
    end
  end
end
