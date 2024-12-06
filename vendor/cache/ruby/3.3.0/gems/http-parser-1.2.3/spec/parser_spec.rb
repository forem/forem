require 'http-parser'

describe HttpParser::Parser, "#initialize" do
    before :each do
        @inst = HttpParser::Parser.new_instance
    end

    describe "callbacks" do
        describe "on_message_begin" do
            subject do
                described_class.new do |parser|
                    parser.on_message_begin { @begun = true }
                end
            end

            it "should trigger on a new request" do
                subject.parse @inst, "GET / HTTP/1.1"
                expect(@begun).to eq(true)
            end
        end

        describe "on_url" do
            let(:expected) { '/foo?q=1' }

            subject do
                described_class.new do |parser|
                    parser.on_url { |inst, data| @url = data }
                end
            end

            it "should pass the recognized url" do
                subject.parse @inst, "GET "

                expect(@url).to be_nil

                subject.parse @inst, "#{expected} HTTP/1.1"

                expect(@url).to eq(expected)
            end
        end

        describe "on_header_field" do
            let(:expected) { 'Host' }

            subject do
                described_class.new do |parser|
                    parser.on_header_field { |inst, data| @header_field = data }
                end
            end

            it "should pass the recognized header-name" do
                subject.parse @inst, "GET /foo HTTP/1.1\r\n"

                expect(@header_field).to be_nil

                subject.parse @inst, "#{expected}: example.com\r\n"

                expect(@header_field).to eq(expected)
            end
        end

        describe "on_header_value" do
            let(:expected) { 'example.com' }

            subject do
                described_class.new do |parser|
                    parser.on_header_value { |inst, data| @header_value = data }
                end
            end

            it "should pass the recognized header-value" do
                subject.parse @inst, "GET /foo HTTP/1.1\r\n"

                expect(@header_value).to be_nil

                subject.parse @inst, "Host: #{expected}\r\n"

                expect(@header_value).to eq(expected)
            end
        end

        describe "on_headers_complete" do
            subject do
                described_class.new do |parser|
                    parser.on_headers_complete { @header_complete = true }
                end
            end

            it "should trigger on the last header" do
                subject.parse @inst, "GET / HTTP/1.1\r\nHost: example.com\r\n"

                expect(@header_complete).to be_nil

                subject.parse @inst, "\r\n"

                expect(@header_complete).to eq(true)
            end

            context "when #stop! is called" do
                subject do
                    described_class.new do |parser|
                        parser.on_headers_complete { @inst.stop! }

                        parser.on_body { |inst, data| @body = data }
                    end
                end

                it "should indicate there is no request body to parse" do
                    subject.parse @inst, "GET / HTTP/1.1\r\nHost: example.com\r\n\r\nBody"

                    expect(@body).to be_nil
                end
            end
        end

        describe "on_body" do
            let(:expected) { "Body" }

            subject do
                described_class.new do |parser|
                    parser.on_body { |inst, data| @body = data }
                end
            end

            it "should trigger on the body" do
                subject.parse @inst, "POST / HTTP/1.1\r\nTransfer-Encoding: chunked\r\n\r\n"

                expect(@body).to be_nil

                subject.parse @inst, "#{"%x" % expected.length}\r\n#{expected}"

                expect(@body).to eq(expected)
            end
        end

        describe "on_message_complete" do
            subject do
                described_class.new do |parser|
                    parser.on_message_complete { @message_complete = true }
                end
            end

            it "should trigger at the end of the message" do
                subject.parse @inst, "GET / HTTP/1.1\r\n"

                expect(@message_complete).to be_nil

                subject.parse @inst, "Host: example.com\r\n\r\n"

                expect(@message_complete).to eq(true)
            end
        end
    end


    describe "#http_method" do
        let(:expected) { :POST }

        it "should set the http_method field" do
            subject.parse @inst, "#{expected} / HTTP/1.1\r\n"

            expect(@inst.http_method).to eq(expected)
        end
    end

    describe "#http_major" do
        let(:expected) { 1 }

        before do
            @inst.type = :request
        end

        context "when parsing requests" do
            it "should set the http_major field" do
                subject.parse @inst, "GET / HTTP/#{expected}."

                expect(@inst.http_major).to eq(expected)
            end
        end

        context "when parsing responses" do
            before do
                @inst.type = :response
            end

            it "should set the http_major field" do
                subject.parse @inst, "HTTP/#{expected}."

                expect(@inst.http_major).to eq(expected)
            end
        end
    end

    describe "#http_minor" do
        let(:expected) { 2 }

        context "when parsing requests" do
            it "should set the http_minor field" do
                subject.parse @inst, "GET / HTTP/1.#{expected}\r\n"

                expect(@inst.http_minor).to eq(expected)
            end
        end

        context "when parsing responses" do
            before do
                @inst.type = :response
            end

            it "should set the http_major field" do
                subject.parse @inst, "HTTP/1.#{expected} "

                expect(@inst.http_minor).to eq(expected)
            end
        end
    end

    describe "#http_version" do
        let(:expected) { '1.1' }

        before do
            subject.parse @inst, "GET / HTTP/#{expected}\r\n"
        end

        it "should combine #http_major and #http_minor" do
            expect(@inst.http_version).to eq(expected)
        end
    end

    describe "#http_status" do
        context "when parsing requests" do
            before do
                subject.parse @inst, "GET / HTTP/1.1\r\nHost: example.com\r\n\r\n"
            end

            it "should not be set" do
                expect(@inst.http_status).to be_zero
            end
        end

        context "when parsing responses" do
            let(:expected) { 200 }

            before do
                @inst.type = :response
                subject.parse @inst, "HTTP/1.1 #{expected} OK\r\n"
                subject.parse @inst, "Location: http://example.com/\r\n\r\n"
            end

            it "should set the http_status field" do
                expect(@inst.http_status).to eq(expected)
            end
        end
    end

    describe "#upgrade?" do
        let(:upgrade) { 'WebSocket' }

        before do
            subject.parse @inst, "GET /demo HTTP/1.1\r\n"
            subject.parse @inst, "Upgrade: #{upgrade}\r\n"
            subject.parse @inst, "Connection: Upgrade\r\n"
            subject.parse @inst, "Host: example.com\r\n"
            subject.parse @inst, "Origin: http://example.com\r\n"
            subject.parse @inst, "WebSocket-Protocol: sample\r\n"
            subject.parse @inst, "\r\n"
        end

        it "should return true if the Upgrade header was set" do
            expect(@inst.upgrade?).to eq(true)
        end
    end

    describe "pipelined requests" do
        subject do
            @begun = 0
            described_class.new do |parser|
                parser.on_message_begin { @begun += 1 }
            end
        end

        it "should trigger on a new request" do
            subject.parse @inst, "GET /demo HTTP/1.1\r\n\r\nGET /demo HTTP/1.1\r\n\r\n"
            expect(@begun).to eq(2)
        end
    end

    describe "method based instead of block based" do
        class SomeParserClass
            attr_reader :url

            def on_url(inst, data)
                @url = data
            end
        end

        let(:expected) { '/foo?q=1' }

        it "should simplify the process" do
            callbacks = SomeParserClass.new
            parser = described_class.new(callbacks)

            parser.parse @inst, "GET "

            expect(callbacks.url).to be_nil

            parser.parse @inst, "#{expected} HTTP/1.1"

            expect(callbacks.url).to eq(expected)
        end
    end
end

