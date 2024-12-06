module Fog
  module AWS
    class DNS
      class Real
        require 'fog/aws/parsers/dns/change_resource_record_sets'

        # Use this action to create or change your authoritative DNS information for a zone
        # http://docs.amazonwebservices.com/Route53/latest/DeveloperGuide/RRSchanges.html#RRSchanges_API
        #
        # ==== Parameters
        # * zone_id<~String> - ID of the zone these changes apply to
        # * options<~Hash>
        #   * comment<~String> - Any comments you want to include about the change.
        # * change_batch<~Array> - The information for a change request
        #   * changes<~Hash> -
        #     * action<~String> - 'CREATE' or 'DELETE'
        #     * name<~String>   - This must be a fully-specified name, ending with a final period
        #     * type<~String>   - A | AAAA | CNAME | MX | NS | PTR | SOA | SPF | SRV | TXT
        #     * ttl<~Integer>   - Time-to-live value - omit if using an alias record
        #     * weight<~Integer>   - Time-to-live value - omit if using an alias record
        #     * set_identifier<~String> - An identifier that differentiates among multiple resource record sets that have the same combination of DNS name and type.
        #     * region<~String> - The Amazon EC2 region where the resource that is specified in this resource record set resides.  (Latency only)
        #     * failover<~String> - To configure failover, you add the Failover element to two resource record sets. For one resource record set, you specify PRIMARY as the value for Failover; for the other resource record set, you specify SECONDARY.
        #     * geo_location<~String XML> - A complex type currently requiring XML that lets you control how Amazon Route 53 responds to DNS queries based on the geographic origin of the query.
        #     * health_check_id<~String> - If you want Amazon Route 53 to return this resource record set in response to a DNS query only when a health check is passing, include the HealthCheckId element and specify the ID of the applicable health check.
        #     * resource_records<~Array> - Omit if using an alias record
        #     * alias_target<~Hash> - Information about the domain to which you are redirecting traffic (Alias record sets only)
        #       * dns_name<~String> - The Elastic Load Balancing domain to which you want to reroute traffic
        #       * hosted_zone_id<~String> - The ID of the hosted zone that contains the Elastic Load Balancing domain to which you want to reroute traffic
        #       * evaluate_target_health<~Boolean> - Applies only to alias, weighted alias, latency alias, and failover alias resource record sets: If you set the value of EvaluateTargetHealth to true, the alias resource record sets inherit the health of the referenced resource record sets.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ChangeInfo'<~Hash>
        #       * 'Id'<~String> - The ID of the request
        #       * 'Status'<~String> - status of the request - PENDING | INSYNC
        #       * 'SubmittedAt'<~String> - The date and time the change was made
        #   * status<~Integer> - 200 when successful
        #
        # ==== Examples
        #
        # Example changing a CNAME record:
        #
        #     change_batch_options = [
        #       {
        #         :action => "DELETE",
        #         :name => "foo.example.com.",
        #         :type => "CNAME",
        #         :ttl => 3600,
        #         :resource_records => [ "baz.example.com." ]
        #       },
        #       {
        #         :action => "CREATE",
        #         :name => "foo.example.com.",
        #         :type => "CNAME",
        #         :ttl => 3600,
        #         :resource_records => [ "bar.example.com." ]
        #       }
        #     ]
        #
        #     change_resource_record_sets("ABCDEFGHIJKLMN", change_batch_options)
        #
        def change_resource_record_sets(zone_id, change_batch, options = {})
          body = Fog::AWS::DNS.change_resource_record_sets_data(zone_id, change_batch, @version, options)
          request({
            :body       => body,
            :idempotent => true,
            :parser     => Fog::Parsers::AWS::DNS::ChangeResourceRecordSets.new,
            :expects    => 200,
            :method     => 'POST',
            :path       => "hostedzone/#{zone_id}/rrset"
          })
        end
      end

      class Mock

        SET_PREFIX = 'SET_'

        def record_exist?(zone,change,change_name)
          return false if zone[:records][change[:type]].nil?
          current_records = zone[:records][change[:type]][change_name]
          return false if current_records.nil?

          if !change[:set_identifier].empty?
            !current_records[change[:SetIdentifier]].nil?
          else
            !current_records.empty?
          end
        end

        def change_resource_record_sets(zone_id, change_batch, options = {})
          response = Excon::Response.new
          errors   = []


          if (zone = self.data[:zones][zone_id])
            response.status = 200

            change_id = Fog::AWS::Mock.change_id
            change_batch.each do |change|

              change_name = change[:name]
              change_name = change_name + "." unless change_name.end_with?(".")

              case change[:action]
              when "CREATE"
                if zone[:records][change[:type]].nil?
                  zone[:records][change[:type]] = {}
                end

                if !record_exist?(zone, change, change_name)
                  # raise change.to_s if change[:resource_records].nil?
                  new_record =
                    if change[:alias_target]
                      record = {
                        :alias_target => change[:alias_target]
                      }
                    else
                      record = {
                        :ttl => change[:ttl].to_s,
                      }
                    end

                  new_record = {
                    :change_id        => change_id,
                    :resource_records => change[:resource_records] || [],
                    :name             => change_name,
                    :type             => change[:type],
                    :set_identifier   => change[:set_identifier],
                    :weight           => change[:weight]
                  }.merge(record)

                  if change[:set_identifier].nil?
                    zone[:records][change[:type]][change_name] = new_record
                  else
                    zone[:records][change[:type]][change_name] = {} if zone[:records][change[:type]][change_name].nil?
                    zone[:records][change[:type]][change_name][SET_PREFIX + change[:set_identifier]] = new_record
                  end
                else
                  errors << "Tried to create resource record set #{change[:name]}. type #{change[:type]}, but it already exists"
                end
              when "DELETE"
                action_performed = false
                if !zone[:records][change[:type]].nil? && !zone[:records][change[:type]][change_name].nil? && !change[:set_identifier].nil?
                  action_performed = true unless zone[:records][change[:type]][change_name].delete(SET_PREFIX + change[:set_identifier]).nil?
                  zone[:records][change[:type]].delete(change_name) if zone[:records][change[:type]][change_name].empty?
                elsif !zone[:records][change[:type]].nil?
                  action_performed = true unless zone[:records][change[:type]].delete(change_name).nil?
                end

                if !action_performed
                  errors << "Tried to delete resource record set #{change[:name]}. type #{change[:type]}, but it was not found"
                end
              end
            end

            if errors.empty?
              change = {
                :id           => change_id,
                :status       => 'PENDING',
                :submitted_at => Time.now.utc.iso8601
              }
              self.data[:changes][change[:id]] = change
              response.body = {
                'Id'          => change[:id],
                'Status'      => change[:status],
                'SubmittedAt' => change[:submitted_at]
              }
              response
            else
              raise Fog::AWS::DNS::Error.new("InvalidChangeBatch => #{errors.join(", ")}")
            end
          else
            raise Fog::AWS::DNS::NotFound.new("NoSuchHostedZone => A hosted zone with the specified hosted zone ID does not exist.")
          end
        end
      end
    end
  end
end
