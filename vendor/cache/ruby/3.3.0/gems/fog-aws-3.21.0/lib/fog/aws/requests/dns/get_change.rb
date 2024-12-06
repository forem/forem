module Fog
  module AWS
    class DNS
      class Real
        require 'fog/aws/parsers/dns/get_change'

        # returns the current state of a change request
        #
        # ==== Parameters
        # * change_id<~String>
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'Id'<~String>
        #     * 'Status'<~String>
        #     * 'SubmittedAt'<~String>
        #   * status<~Integer> - 200 when successful
        def get_change(change_id)
          # AWS methods return change_ids that looks like '/change/id'.  Let the caller either use
          # that form or just the actual id (which is what this request needs)
          change_id = change_id.sub('/change/', '')

          request({
            :expects => 200,
            :parser  => Fog::Parsers::AWS::DNS::GetChange.new,
            :method  => 'GET',
            :path    => "change/#{change_id}"
          })
        end
      end

      class Mock
        def get_change(change_id)
          response = Excon::Response.new
          # find the record with matching change_id
          # records = data[:zones].values.map{|z| z[:records].values.map{|r| r.values}}.flatten
          change = self.data[:changes][change_id] ||
            raise(Fog::AWS::DNS::NotFound.new("NoSuchChange => Could not find resource with ID: #{change_id}"))

          response.status = 200
          submitted_at = Time.parse(change[:submitted_at])
          response.body = {
            'Id' => change[:id],
            # set as insync after some time
            'Status' => (submitted_at + Fog::Mock.delay) < Time.now ? 'INSYNC' : change[:status],
            'SubmittedAt' => change[:submitted_at]
          }
          response
        end
      end
    end
  end
end
