module VCR
  module Middleware
    module Excon
      # Contains legacy methods only needed when integrating with older versions
      # of Excon.
      # @api private
      module LegacyMethods
        # based on:
        # https://github.com/geemus/excon/blob/v0.7.8/lib/excon/connection.rb#L117-132
        def query
          @query ||= case request_params[:query]
            when String
              "?#{request_params[:query]}"
            when Hash
              qry = '?'
              for key, values in request_params[:query]
                if values.nil?
                  qry << key.to_s << '&'
                else
                  for value in [*values]
                    qry << key.to_s << '=' << CGI.escape(value.to_s) << '&'
                  end
                end
              end
              qry.chop! # remove trailing '&'
            else
              ''
          end
        end
      end
    end
  end
end
