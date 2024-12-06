require 'http-parser'

describe HttpParser::Parser, "#initialize" do
    before :each do
        @inst = HttpParser::Parser.new_instance
    end

    it "should return true when error" do
        expect(subject.parse(@inst, "GETS / HTTP/1.1\r\n")).to eq(true)
        expect(@inst.error?).to eq(true)
    end

    it "should return false on success" do
        expect(subject.parse(@inst, "GET / HTTP/1.1\r\n")).to eq(false)
        expect(@inst.error?).to eq(false)
    end

    it "the error should be inspectable" do
        expect(subject.parse(@inst, "GETS / HTTP/1.1\r\n")).to eq(true)
        expect(@inst.error).to be_kind_of(::HttpParser::Error::INVALID_METHOD)
        expect(@inst.error?).to eq(true)
    end

    it "raises different error types depending on the error" do
        expect(subject.parse(@inst, "GET / HTTP/23\r\n")).to eq(true)
        expect(@inst.error).to be_kind_of(::HttpParser::Error::INVALID_VERSION)
        expect(@inst.error?).to eq(true)
    end

    context "callback errors" do
        subject do
            described_class.new do |parser|
                parser.on_url { |inst, data| raise 'unhandled' }
            end
        end

        it "should handle unhandled errors gracefully" do
            expect(subject.parse(@inst, "GET /foo?q=1 HTTP/1.1")).to eq(true)

            expect(@inst.error?).to eq(true)
            expect(@inst.error).to be_kind_of(::HttpParser::Error::CALLBACK)
        end
    end
end

