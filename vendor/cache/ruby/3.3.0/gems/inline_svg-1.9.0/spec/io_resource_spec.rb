require_relative '../lib/inline_svg'
require "stringio"
require "tempfile"

describe InlineSvg::IOResource do
  it "support api methods" do
    is_expected.to respond_to(:===, :read)
  end

  describe '#===' do
    context 'return true' do
      it "for IO object" do
        read_io, write_io = IO.pipe
        expect(subject === read_io).to be true
        expect(subject === write_io).to be true
      end

      it "for StringIO object" do
        expect(subject === StringIO.new).to be true
      end

      it "for File object" do
        expect(subject === File.new("#{Dir.tmpdir}/testfile", "w")).to be true
      end
    end
    context 'return false' do
      it "for String object" do
        expect(subject === "string/filename").to be false
      end
    end
  end

  describe '#read' do

    tests = proc do
      it "closed raise error" do
        rio.close
        expect do 
          subject.read(rio)
        end.to raise_error(IOError)
      end

      it "empty" do
        rio.read
        expect(subject.read rio).to eq ''
      end

      it "twice" do
        expect(subject.read rio).to eq answer
        expect(subject.read rio).to eq answer
      end

      it "write only raise error" do
        expect do 
          subject.read wio
        end.to raise_error(IOError)
      end
    end

    context 'IO object' do
      let(:answer) { 'read' }
      let(:rio) { StringIO.new(answer, 'r') }
      let(:wio) { StringIO.new('write', 'w') }
      instance_exec &tests
    end

    context 'File object' do
      let(:file_path) { File.expand_path('../files/example.svg', __FILE__) }
      let(:answer) { File.read(file_path) }
      let(:rio) { File.new(file_path, 'r') }
      let(:wio) { File.new('/dev/null', 'w') }
      instance_exec &tests
      it 'has non empty body' do
        expect(answer).to_not eq ''
      end
    end

    
  end
end
