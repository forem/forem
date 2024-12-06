module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/basic'

        # Modifies a network interface attribute value
        #
        # ==== Parameters
        # * network_interface_id<~String> - The ID of the network interface you want to describe an attribute of
        # * attribute<~String>            - The attribute to modify, must be one of 'description', 'groupSet', 'sourceDestCheck' or 'attachment'
        # * value<~Object>                - New value of attribute, the actual tyep depends on teh attribute:
        #                                   description     - a string
        #                                   groupSet        - a list of group id's
        #                                   sourceDestCheck - a boolean value
        #                                   attachment      - a hash with:
        #                                                       attachmentid - the attachment to change
        #                                                       deleteOnTermination - a boolean
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/2012-03-01/APIReference/ApiReference-query-ModifyNetworkInterfaceAttribute.html]
        def modify_network_interface_attribute(network_interface_id, attribute, value)
          params = {}
          case attribute
          when 'description'
            params['Description.Value'] = value
          when 'groupSet'
            params.merge!(Fog::AWS.indexed_param('SecurityGroupId.%d', value))
          when 'sourceDestCheck'
            params['SourceDestCheck.Value'] = value
          when 'attachment'
            params['Attachment.AttachmentId']        = value['attachmentId']
            params['Attachment.DeleteOnTermination'] = value['deleteOnTermination']
          else
            raise Fog::AWS::Compute::Error.new("Illegal attribute '#{attribute}' specified")
          end

          request({
            'Action'             => 'ModifyNetworkInterfaceAttribute',
            'NetworkInterfaceId' => network_interface_id,
            :parser              => Fog::Parsers::AWS::Compute::Basic.new
          }.merge!(params))
        end
      end

      class Mock
        def modify_network_interface_attribute(network_interface_id, attribute, value)
          response = Excon::Response.new
          if self.data[:network_interfaces][network_interface_id]
            nic = self.data[:network_interfaces][network_interface_id]

            case attribute
            when 'description'
              nic['description'] = value.clone
            when 'groupSet'
              groups = {}
              value.each do |group_id|
                security_group = self.data[:security_groups][group_id]
                if security_group.nil?
                  raise Fog::AWS::Compute::Error.new("Unknown security group '#{group_id}' specified")
                end
                groups[group_id] = security_group['groupName']
              end
              nic['groupSet'] = groups
            when 'sourceDestCheck'
              nic['sourceDestCheck'] = value
            when 'attachment'
              if nic['attachment'].nil? || value['attachmentId'] != nic['attachment']['attachmentId']
                raise Fog::AWS::Compute::Error.new("Illegal attachment '#{value['attachmentId']}' specified")
              end
              nic['attachment']['deleteOnTermination'] = value['deleteOnTermination']
            else
              raise Fog::AWS::Compute::Error.new("Illegal attribute '#{attribute}' specified")
            end

            response.status = 200
            response.body = {
              'requestId' => Fog::AWS::Mock.request_id,
              'return'    => true
            }

            response
          else
            raise Fog::AWS::Compute::NotFound.new("The network interface '#{network_interface_id}' does not exist")
          end
        end
      end
    end
  end
end
