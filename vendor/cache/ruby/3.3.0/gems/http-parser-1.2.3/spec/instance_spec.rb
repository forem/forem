require 'http-parser'

describe ::HttpParser::Instance, "#initialize" do
    context "when given a block" do
        it "should yield the new Instance" do
            expected = nil

            described_class.new { |inst| expected = inst }

            expect(expected).to be_kind_of(described_class)
        end

        it "should allow changing the parser type" do
            inst = described_class.new do |inst|
                inst.type = :request
            end

            expect(inst.type).to eq(:request)
        end
    end

    describe "#type" do
        it "should default to :both" do
            expect(subject.type).to eq(:both)
        end

        it "should convert the type to a Symbol" do
            subject[:type_flags] = ::HttpParser::TYPES[:request]

            expect(subject.type).to eq(:request)
        end

        it "should extract the type from the type_flags field" do
            subject[:type_flags] = ((0xff & ~0x3) | ::HttpParser::TYPES[:response])

            expect(subject.type).to eq(:response)
        end
    end

    describe "#type=" do
        it "should set the type" do
            subject.type = :response

            expect(subject.type).to eq(:response)
        end

        it "should not change flags" do
            flags = (0xff & ~0x3)
            subject[:type_flags] = flags

            subject.type = :request

            expect(subject[:type_flags]).to eq((flags | ::HttpParser::TYPES[:request]))
        end
    end

    describe "#stop!" do
        it "should throw :return, 1" do
            expect { subject.stop! }.to throw_symbol(:return,1)
        end
    end

    describe "#error!" do
        it "should throw :return, -1" do
            expect { subject.error! }.to throw_symbol(:return,-1)
        end
    end

    it "should not change the type" do
        inst = described_class.new do |inst|
            inst.type = :request
        end

        inst.reset!
        expect(inst.type).to eq(:request)
    end
end

