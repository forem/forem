module Fog
  module AWS
    class DNS
      class Real
        require 'fog/aws/parsers/dns/delete_hosted_zone'

        # Delete a hosted zone
        #
        # ==== Parameters
        # * zone_id<~String> -
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ChangeInfo'<~Hash> -
        #       * 'Id'<~String> The ID of the request
        #       * 'Status'<~String> The current state of the hosted zone
        #       * 'SubmittedAt'<~String> The date and time the change was made
        #   * status<~Integer> - 200 when successful
        def delete_hosted_zone(zone_id)
          # AWS methods return zone_ids that looks like '/hostedzone/id'.  Let the caller either use
          # that form or just the actual id (which is what this request needs)
          zone_id = zone_id.sub('/hostedzone/', '')

          request({
            :expects => 200,
            :parser  => Fog::Parsers::AWS::DNS::DeleteHostedZone.new,
            :method  => 'DELETE',
            :path    => "hostedzone/#{zone_id}"
          })
        end
      end

      class Mock
        require 'time'

        def delete_hosted_zone(zone_id)
          response = Excon::Response.new
          key = [zone_id, "/hostedzone/#{zone_id}"].find { |k| !self.data[:zones][k].nil? } ||
            raise(Fog::AWS::DNS::NotFound.new("NoSuchHostedZone => A hosted zone with the specified hosted zone does not exist."))

            change = {
              :id => Fog::AWS::Mock.change_id,
              :status => 'INSYNC',
              :submitted_at => Time.now.utc.iso8601
            }

            self.data[:changes][change[:id]] = change

            response.status = 200
            response.body = {
              'ChangeInfo' => {
                'Id' => change[:id],
                'Status' => change[:status],
                'SubmittedAt' => change[:submitted_at]
              }
            }
            self.data[:zones].delete(key)
            response
        end
      end
    end
  end
end
