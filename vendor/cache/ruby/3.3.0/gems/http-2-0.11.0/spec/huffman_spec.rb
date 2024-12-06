require 'helper'

RSpec.describe HTTP2::Header::Huffman do
  huffman_examples = [ # plain, encoded
    ['www.example.com', 'f1e3c2e5f23a6ba0ab90f4ff'],
    ['no-cache',        'a8eb10649cbf'],
    ['Mon, 21 Oct 2013 20:13:21 GMT', 'd07abe941054d444a8200595040b8166e082a62d1bff'],
  ]
  context 'encode' do
    before(:all) { @encoder = HTTP2::Header::Huffman.new }
    huffman_examples.each do |plain, encoded|
      it "should encode #{plain} into #{encoded}" do
        expect(@encoder.encode(plain).unpack('H*').first).to eq encoded
      end
    end
  end
  context 'decode' do
    before(:all) { @encoder = HTTP2::Header::Huffman.new }
    huffman_examples.each do |plain, encoded|
      it "should decode #{encoded} into #{plain}" do
        expect(@encoder.decode(HTTP2::Buffer.new([encoded].pack('H*')))).to eq plain
      end
    end

    [
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:16.0) Gecko/20100101 Firefox/16.0',
      'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'http://www.craigslist.org/about/sites/',
      'cl_b=AB2BKbsl4hGM7M4nH5PYWghTM5A; cl_def_lang=en; cl_def_hp=shoals',
      'image/png,image/*;q=0.8,*/*;q=0.5',
      'BX=c99r6jp89a7no&b=3&s=q4; localization=en-us%3Bus%3Bus',
      'UTF-8でエンコードした日本語文字列',
    ].each do |string|
      it "should encode then decode '#{string}' into the same" do
        s = string.dup.force_encoding(Encoding::BINARY)
        encoded = @encoder.encode(s)
        expect(@encoder.decode(HTTP2::Buffer.new(encoded))).to eq s
      end
    end

    it 'should encode/decode all_possible 2-byte sequences' do
      (2**16).times do |n|
        str = [n].pack('V')[0, 2].force_encoding(Encoding::BINARY)
        expect(@encoder.decode(HTTP2::Buffer.new(@encoder.encode(str)))).to eq str
      end
    end

    it 'should raise when input is shorter than expected' do
      encoded = huffman_examples.first.last
      encoded = [encoded].pack('H*')
      expect { @encoder.decode(HTTP2::Buffer.new(encoded[0...-1])) }.to raise_error(/EOS invalid/)
    end
    it 'should raise when input is not padded by 1s' do
      encoded = 'f1e3c2e5f23a6ba0ab90f4fe' # note the fe at end
      encoded = [encoded].pack('H*')
      expect { @encoder.decode(HTTP2::Buffer.new(encoded)) }.to raise_error(/EOS invalid/)
    end
    it 'should raise when exceedingly padded' do
      encoded = 'e7cf9bebe89b6fb16fa9b6ffff' # note the extra ff
      encoded = [encoded].pack('H*')
      expect { @encoder.decode(HTTP2::Buffer.new(encoded)) }.to raise_error(/EOS invalid/)
    end
    it 'should raise when EOS is explicitly encoded' do
      encoded = ['1c7fffffffff'].pack('H*') # a b EOS
      expect { @encoder.decode(HTTP2::Buffer.new(encoded)) }.to raise_error(/EOS found/)
    end
  end
end
