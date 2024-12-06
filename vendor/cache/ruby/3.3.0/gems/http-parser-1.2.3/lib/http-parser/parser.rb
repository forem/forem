# frozen_string_literal: true

module HttpParser
    class Parser
        CALLBACKS = [
            :on_message_begin, :on_url, :on_status, :on_header_field, :on_header_value,
            :on_headers_complete, :on_body, :on_message_complete, :on_chunk_header, :on_chunk_complete
        ]

        #
        # Returns a new request/response instance variable
        #
        def self.new_instance(&block)
            ::HttpParser::Instance.new(&block)
        end


        #
        # Initializes the Parser instance.
        #
        def initialize(callback_obj = nil)
            @settings = ::HttpParser::Settings.new
            @callbacks = {} # so GC doesn't clean them up on java

            if not callback_obj.nil?
                CALLBACKS.each do |callback|
                    self.__send__(callback, &callback_obj.method(callback)) if callback_obj.respond_to? callback
                end
            end

            yield self if block_given?
        end

        #
        # Registers an `on_message_begin` callback.
        #
        # @yield [instance]
        #   The given block will be called when the HTTP message begins.
        #
        # @yieldparam [HttpParser::Instance] instance
        #   The state so far of the request / response being processed.
        #
        def on_message_begin(&block)
            cb = Callback.new(&block)
            @callbacks[:on_message_begin] = cb
            @settings[:on_message_begin] = cb
        end

        #
        # Registers an `on_url` callback.
        #
        # @yield [instance, url]
        #   The given block will be called when the Request URI is recognized
        #   within the Request-Line.
        #
        # @yieldparam [HttpParser::Instance] instance
        #   The state so far of the request / response being processed.
        #
        # @yieldparam [String] url
        #   The recognized Request URI.
        #
        # @see http://www.w3.org/Protocols/rfc2616/rfc2616-sec5.html#sec5.1.2
        #
        def on_url(&block)
            cb = DataCallback.new(&block)
            @callbacks[:on_url] = cb
            @settings[:on_url] = cb
        end

        #
        # Registers an `on_status_complete` callback.
        #
        # @yield [instance]
        #   The given block will be called when the status is recognized.
        #
        # @yieldparam [HttpParser::Instance] instance
        #   The state so far of the request / response being processed.
        #
        def on_status(&block)
            cb = DataCallback.new(&block)
            @callbacks[:on_status] = cb
            @settings[:on_status] = cb
        end

        #
        # Registers an `on_header_field` callback.
        #
        # @yield [instance, field]
        #   The given block will be called when a Header name is recognized
        #   in the Headers.
        #
        # @yieldparam [HttpParser::Instance] instance
        #   The state so far of the request / response being processed.
        #
        # @yieldparam [String] field
        #   A recognized Header name.
        #
        # @see http://www.w3.org/Protocols/rfc2616/rfc2616-sec4.html#sec4.5
        #
        def on_header_field(&block)
            cb = DataCallback.new(&block)
            @callbacks[:on_header_field] = cb
            @settings[:on_header_field] = cb
        end

        #
        # Registers an `on_header_value` callback.
        #
        # @yield [instance, value]
        #   The given block will be called when a Header value is recognized
        #   in the Headers.
        #
        # @yieldparam [HttpParser::Instance] instance
        #   The state so far of the request / response being processed.
        #
        # @yieldparam [String] value
        #   A recognized Header value.
        #
        # @see http://www.w3.org/Protocols/rfc2616/rfc2616-sec4.html#sec4.5
        #
        def on_header_value(&block)
            cb = DataCallback.new(&block)
            @callbacks[:on_header_value] = cb
            @settings[:on_header_value] = cb
        end

        #
        # Registers an `on_headers_complete` callback.
        #
        # @yield [instance]
        #   The given block will be called when the Headers stop.
        #
        # @yieldparam [HttpParser::Instance] instance
        #   The state so far of the request / response being processed.
        #
        def on_headers_complete(&block)
            cb = Callback.new(&block)
            @callbacks[:on_headers_complete] = cb
            @settings[:on_headers_complete] = cb
        end

        #
        # Registers an `on_body` callback.
        #
        # @yield [instance, body]
        #   The given block will be called when the body is recognized in the
        #   message body.
        #
        # @yieldparam [HttpParser::Instance] instance
        #   The state so far of the request / response being processed.
        #
        # @yieldparam [String] body
        #   The full body or a chunk of the body from a chunked
        #   Transfer-Encoded stream.
        #
        # @see http://www.w3.org/Protocols/rfc2616/rfc2616-sec4.html#sec4.5
        #
        def on_body(&block)
            cb = DataCallback.new(&block)
            @callbacks[:on_body] = cb
            @settings[:on_body] = cb
        end

        #
        # Registers an `on_message_begin` callback.
        #
        # @yield [instance]
        #   The given block will be called when the message completes.
        #
        # @yieldparam [HttpParser::Instance] instance
        #   The state so far of the request / response being processed.
        #
        def on_message_complete(&block)
            cb = Callback.new(&block)
            @callbacks[:on_message_complete] = cb
            @settings[:on_message_complete] = cb
        end

        #
        # Registers an `on_chunk_header` callback.
        #
        # @yield [instance]
        #   The given block will be called when a new chunk header is received.
        #
        # @yieldparam [HttpParser::Instance] instance
        #   The state so far of the request / response being processed.
        #
        def on_chunk_header(&block)
            cb = Callback.new(&block)
            @callbacks[:on_message_complete] = cb
            @settings[:on_message_complete] = cb
        end

        #
        # Registers an `on_chunk_complete` callback.
        #
        # @yield [instance]
        #   The given block will be called when the current chunk completes.
        #
        # @yieldparam [HttpParser::Instance] instance
        #   The state so far of the request / response being processed.
        #
        def on_chunk_complete(&block)
            cb = Callback.new(&block)
            @callbacks[:on_message_complete] = cb
            @settings[:on_message_complete] = cb
        end

        #
        # Parses data.
        #
        # @param [HttpParser::Instance] inst
        #   The state so far of the request / response being processed.
        #
        # @param [String] data
        #   The data to parse against the instance specified.
        #
        # @return [Boolean]
        #   Returns true if the data was parsed successfully.
        #
        def parse(inst, data)
            ::HttpParser.http_parser_execute(inst, @settings, data, data.length)
            return inst.error?
        end


        protected


        class Callback < ::FFI::Function
            #
            # Creates a new Parser callback.
            #
            def self.new(&block)
                super(:int, [::HttpParser::Instance.ptr]) do |parser|
                    begin
                        catch(:return) { yield(parser); 0 }
                    rescue
                        -1
                    end
                end
            end
        end

        class DataCallback < ::FFI::Function
            def self.new(&block)
                super(:int, [::HttpParser::Instance.ptr, :pointer, :size_t]) do |parser, buffer, length|
                    begin
                        data = buffer.get_bytes(0, length)
                        catch(:return) { yield(parser, data); 0 }
                    rescue
                        -1
                    end
                end
            end
        end
    end
end
