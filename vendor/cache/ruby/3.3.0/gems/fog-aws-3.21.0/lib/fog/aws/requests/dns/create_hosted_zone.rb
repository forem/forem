module Fog
  module AWS
    class DNS
      class Real
        require 'fog/aws/parsers/dns/create_hosted_zone'

        # Creates a new hosted zone
        #
        # ==== Parameters
        # * name<~String> - The name of the domain. Must be a fully-specified domain that ends with a period
        # * options<~Hash>
        #   * caller_ref<~String> - unique string that identifies the request & allows failed
        #                           calls to be retried without the risk of executing the operation twice
        #   * comment<~String> -
        #   * vpc_id<~String> - specify both a VPC's ID and its region to create a private zone for that VPC
        #   * vpc_region<~String> - specify both a VPC's ID and its region to create a private zone for that VPC
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'HostedZone'<~Hash>:
        #       * 'Id'<~String> -
        #       * 'Name'<~String> -
        #       * 'CallerReference'<~String>
        #       * 'Comment'<~String> -
        #     * 'ChangeInfo'<~Hash> -
        #       * 'Id'<~String>
        #       * 'Status'<~String>
        #       * 'SubmittedAt'<~String>
        #     * 'NameServers'<~Array>
        #       * 'NameServer'<~String>
        #   * status<~Integer> - 201 when successful
        def create_hosted_zone(name, options = {})
          optional_tags = ''
          if options[:caller_ref]
            optional_tags += "<CallerReference>#{options[:caller_ref]}</CallerReference>"
          else
            #make sure we have a unique call reference
            caller_ref = "ref-#{rand(1000000).to_s}"
            optional_tags += "<CallerReference>#{caller_ref}</CallerReference>"
          end
          if options[:comment]
            optional_tags += "<HostedZoneConfig><Comment>#{options[:comment]}</Comment></HostedZoneConfig>"
          end
          if options[:vpc_id] and options[:vpc_region]
            optional_tags += "<VPC><VPCId>#{options[:vpc_id]}</VPCId><VPCRegion>#{options[:vpc_region]}</VPCRegion></VPC>"
          end

          request({
            :body    => %Q{<?xml version="1.0" encoding="UTF-8"?><CreateHostedZoneRequest xmlns="https://route53.amazonaws.com/doc/#{@version}/"><Name>#{name}</Name>#{optional_tags}</CreateHostedZoneRequest>},
            :parser  => Fog::Parsers::AWS::DNS::CreateHostedZone.new,
            :expects => 201,
            :method  => 'POST',
            :path    => "hostedzone"
          })
        end
      end

      class Mock
        require 'time'

        def create_hosted_zone(name, options = {})
          # Append a trailing period to the name if absent.
          name = name + "." unless name.end_with?(".")

          response = Excon::Response.new
          if list_hosted_zones.body['HostedZones'].select {|z| z['Name'] == name}.size < self.data[:limits][:duplicate_domains]
            response.status = 201
            if options[:caller_ref]
              caller_ref = options[:caller_ref]
            else
              #make sure we have a unique call reference
              caller_ref = "ref-#{rand(1000000).to_s}"
            end
            zone_id = "/hostedzone/#{Fog::AWS::Mock.zone_id}"
            self.data[:zones][zone_id] = {
              :id => zone_id,
              :name => name,
              :reference => caller_ref,
              :comment => options[:comment],
              :records => {}
            }
            change = {
              :id => Fog::AWS::Mock.change_id,
              :status => 'PENDING',
              :submitted_at => Time.now.utc.iso8601
            }
            self.data[:changes][change[:id]] = change
            response.body = {
              'HostedZone' => {
                'Id' => zone_id,
                'Name' => name,
                'CallerReference' => caller_ref,
                'Comment' => options[:comment]
              },
              'ChangeInfo' => {
                'Id' => change[:id],
                'Status' => change[:status],
                'SubmittedAt' => change[:submitted_at]
              },
              'NameServers' => Fog::AWS::Mock.nameservers
            }
            response
          else
            raise Fog::AWS::DNS::Error.new("DelegationSetNotAvailable => Amazon Route 53 allows some duplication, but Amazon Route 53 has a maximum threshold of duplicated domains. This error is generated when you reach that threshold. In this case, the error indicates that too many hosted zones with the given domain name exist. If you want to create a hosted zone and Amazon Route 53 generates this error, contact Customer Support.")
          end
        end
      end
    end
  end
end
