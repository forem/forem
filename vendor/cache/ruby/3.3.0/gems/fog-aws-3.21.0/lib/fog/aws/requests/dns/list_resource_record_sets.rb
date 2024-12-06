module Fog
  module AWS
    class DNS
      class Real
        require 'fog/aws/parsers/dns/list_resource_record_sets'

        # list your resource record sets
        #
        # ==== Parameters
        # * zone_id<~String> -
        # * options<~Hash>
        #   * type<~String> -
        #   * name<~String> -
        #   * identifier<~String> -
        #   * max_items<~Integer> -
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResourceRecordSet'<~Array>:
        #       * 'Name'<~String> -
        #       * 'Type'<~String> -
        #       * 'TTL'<~Integer> -
        #       * 'AliasTarget'<~Hash> -
        #         * 'HostedZoneId'<~String> -
        #         * 'DNSName'<~String> -
        #       * 'ResourceRecords'<~Array>
        #         * 'Value'<~String> -
        #     * 'IsTruncated'<~String> -
        #     * 'MaxItems'<~String> -
        #     * 'NextRecordName'<~String>
        #     * 'NextRecordType'<~String>
        #     * 'NextRecordIdentifier'<~String>
        #   * status<~Integer> - 201 when successful
        def list_resource_record_sets(zone_id, options = {})
          # AWS methods return zone_ids that looks like '/hostedzone/id'.  Let the caller either use
          # that form or just the actual id (which is what this request needs)
          zone_id = zone_id.sub('/hostedzone/', '')

          parameters = {}
          options.each do |option, value|
            case option
            when :type, :name, :identifier
              parameters[option] = "#{value}"
            when :max_items
              parameters['maxitems'] = "#{value}"
            end
          end

          request({
            :expects => 200,
            :idempotent => true,
            :method  => 'GET',
            :parser  => Fog::Parsers::AWS::DNS::ListResourceRecordSets.new,
            :path    => "hostedzone/#{zone_id}/rrset",
            :query   => parameters
          })
        end
      end

      class Mock
        def list_all_records(record, zone, name)
          [].tap do |tmp_records|
            tmp_records.push(record) if !record[:name].nil? && ( name.nil? || record[:name].gsub(zone[:name],"") >= name)
            record.each do |key,subr|
              if subr.is_a?(Hash) && key.is_a?(String) &&
                key.start_with?(Fog::AWS::DNS::Mock::SET_PREFIX)
                if name.nil?
                  tmp_records.append(subr)
                else
                  tmp_records.append(subr) if !subr[:name].nil? && subr[:name].gsub(zone[:name],"") >= name
                end
              end
            end
          end
        end

        def list_resource_record_sets(zone_id, options = {})
          maxitems = [options[:max_items]||100,100].min

          response = Excon::Response.new

          zone = self.data[:zones][zone_id] ||
            raise(Fog::AWS::DNS::NotFound.new("NoSuchHostedZone => A hosted zone with the specified hosted zone ID does not exist."))

          records = if options[:type]
                      records_type = zone[:records][options[:type]]
                      records_type.values if records_type
                    else
                      zone[:records].values.map{|r| r.values}.flatten
                    end

          records ||= []

          tmp_records = []
          if options[:name]
            name = options[:name].gsub(zone[:name],"")

            records.each do |r|
              tmp_records += list_all_records(r, zone, name)
            end
          else
            records.each do |r|
              tmp_records += list_all_records(r, zone, nil)
            end
          end
          records = tmp_records

          # sort for pagination
          records.sort! { |a,b| a[:name].gsub(zone[:name],"") <=> b[:name].gsub(zone[:name],"") }


          next_record  = records[maxitems]
          records      = records[0, maxitems]
          truncated    = !next_record.nil?

          response.status = 200
          response.body = {
            'ResourceRecordSets' => records.map do |r|
              if r[:alias_target]
                record = {
                  'AliasTarget' => {
                    'HostedZoneId' => r[:alias_target][:hosted_zone_id],
                    'DNSName' => r[:alias_target][:dns_name]
                  }
                }
              else
                record = {
                  'TTL' => r[:ttl]
                }
              end
              {
                'ResourceRecords' => r[:resource_records],
                'Name' => r[:name],
                'Type' => r[:type],
                'SetIdentifier' => r[:set_identifier],
                'Weight' => r[:weight]
              }.merge(record)
            end,
            'MaxItems' => maxitems,
            'IsTruncated' => truncated
          }

          if truncated
            response.body['NextRecordName'] = next_record[:name]
            response.body['NextRecordType'] = next_record[:type]
          end

          response
        end
      end
    end
  end
end
