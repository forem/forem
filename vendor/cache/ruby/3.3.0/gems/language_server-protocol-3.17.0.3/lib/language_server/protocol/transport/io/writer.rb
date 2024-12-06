module LanguageServer
  module Protocol
    module Transport
      module Io
        class Writer
          attr_reader :io

          def initialize(io)
            @io = io
            io.binmode
          end

          def write(response)
            response_str = response.merge(
              jsonrpc: "2.0"
            ).to_json

            headers = {
              "Content-Length" => response_str.bytesize
            }

            headers.each do |k, v|
              io.print "#{k}: #{v}\r\n"
            end

            io.print "\r\n"

            io.print response_str
            io.flush
          end
        end
      end
    end
  end
end
