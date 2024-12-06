module Fog
  module AWS
    class Storage
      class Real
        # Sync clock against S3 to avoid skew errors
        #
        def sync_clock
          response = begin
            Excon.get(sync_clock_url)
          rescue Excon::Errors::HTTPStatusError => error
            error.response
          end
          Fog::Time.now = Time.parse(response.headers['Date'])
        end

        private

        def sync_clock_url
          host = @acceleration ? region_to_host(@region) : @host

          "#{@scheme}://#{host}:#{@port}"
        end
      end # Real

      class Mock # :nodoc:all
        def sync_clock
          true
        end
      end # Mock
    end # Storage
  end # AWS
end # Fog
