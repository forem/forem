module Fog
  module Parsers
    module AWS
      module Storage
        class GetBucketLifecycle < Fog::Parsers::Base
          def reset
            @expiration = {}
            @version_expiration = {}
            @transition = {}
            @version_transition = {}
            @rule = {}
            @response = { 'Rules' => [] }
          end

          def start_element(name, attrs=[])
            super
            case name
            when 'Expiration'
              @in_expiration = true
            when 'Transition'
              @in_transition = true
            when 'NoncurrentVersionExpiration'
              @in_version_expiration = true
            when 'NoncurrentVersionTransition'
              @in_version_transition = true
            end
          end

          def end_element(name)
            if @in_expiration
              case name
              when 'Days'
                @expiration[name] = value.to_i
              when 'Date'
                @expiration[name] = value
              when 'Expiration'
                @rule['Expiration'] = @expiration
                @in_expiration = false
                @expiration = {}
              end
            elsif @in_version_expiration
              case name
              when 'NoncurrentDays'
                @version_expiration[name] = value.to_i
              when 'Date'
                @version_expiration[name] = value
              when 'NoncurrentVersionExpiration'
                @rule['NoncurrentVersionExpiration'] = @version_expiration
                @in_version_expiration = false
                @version_expiration = {}
              end
            elsif @in_transition
              case name
              when 'StorageClass',
                @transition['StorageClass'] = value
              when 'Date'
                @transition[name] = value
              when 'Days'
                @transition[name] = value.to_i
              when 'Transition'
                @rule['Transition'] = @transition
                @in_transition = false
                @transition = {}
              end
            elsif @in_version_transition
              case name
              when 'StorageClass',
                @version_transition['StorageClass'] = value
              when 'Date'
                @version_transition[name] = value
              when 'NoncurrentDays'
                @version_transition[name] = value.to_i
              when 'NoncurrentVersionTransition'
                @rule['NoncurrentVersionTransition'] = @transition
                @in_version_transition = false
                @version_transition = {}
              end
            else
              case name
              when 'ID', 'Prefix'
                @rule[name] = value
              when 'Status'
                @rule['Enabled'] = value == 'Enabled'
              when 'Rule'
                @response['Rules'] << @rule
                @rule = {}
              end
            end
          end
        end
      end
    end
  end
end
