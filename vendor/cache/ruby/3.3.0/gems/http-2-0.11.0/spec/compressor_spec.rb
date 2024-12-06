require 'helper'

RSpec.describe HTTP2::Header do
  let(:c) { Compressor.new }
  let(:d) { Decompressor.new }

  context 'literal representation' do
    context 'integer' do
      it 'should encode 10 using a 5-bit prefix' do
        buf = c.integer(10, 5)
        expect(buf).to eq [10].pack('C')
        expect(d.integer(Buffer.new(buf), 5)).to eq 10
      end

      it 'should encode 10 using a 0-bit prefix' do
        buf = c.integer(10, 0)
        expect(buf).to eq [10].pack('C')
        expect(d.integer(Buffer.new(buf), 0)).to eq 10
      end

      it 'should encode 1337 using a 5-bit prefix' do
        buf = c.integer(1337, 5)
        expect(buf).to eq [31, 128 + 26, 10].pack('C*')
        expect(d.integer(Buffer.new(buf), 5)).to eq 1337
      end

      it 'should encode 1337 using a 0-bit prefix' do
        buf = c.integer(1337, 0)
        expect(buf).to eq [128 + 57, 10].pack('C*')
        expect(d.integer(Buffer.new(buf), 0)).to eq 1337
      end
    end

    context 'string' do
      [
        ['with huffman',    :always, 0x80],
        ['without huffman', :never,  0],
      ].each do |desc, option, msb|
        let(:trailer) { 'trailer' }

        [
          ['ascii codepoints', 'abcdefghij'],
          ['utf-8 codepoints', 'éáűőúöüó€'],
          ['long utf-8 strings', 'éáűőúöüó€' * 100],
        ].each do |datatype, plain|
          it "should handle #{datatype} #{desc}" do
            # NOTE: don't put this new in before{} because of test case shuffling
            @c = Compressor.new(huffman: option)
            str = @c.string(plain)
            expect(str.getbyte(0) & 0x80).to eq msb

            buf = Buffer.new(str + trailer)
            expect(d.string(buf)).to eq plain
            expect(buf).to eq trailer
          end
        end
      end
      context 'choosing shorter representation' do
        [['日本語', :plain],
         ['200', :huffman],
         ['xq', :plain],   # prefer plain if equal size
        ].each do |string, choice|
          before { @c = Compressor.new(huffman: :shorter) }

          it "should return #{choice} representation" do
            wire = @c.string(string)
            expect(wire.getbyte(0) & 0x80).to eq(choice == :plain ? 0 : 0x80)
          end
        end
      end
    end
  end

  context 'header representation' do
    it 'should handle indexed representation' do
      h = { name: 10, type: :indexed }
      wire = c.header(h)
      expect(wire.readbyte(0) & 0x80).to eq 0x80
      expect(wire.readbyte(0) & 0x7f).to eq h[:name] + 1
      expect(d.header(wire)).to eq h
    end
    it 'should raise when decoding indexed representation with index zero' do
      h = { name: 10, type: :indexed }
      wire = c.header(h)
      wire[0] = 0x80.chr(Encoding::BINARY)
      expect { d.header(wire) }.to raise_error CompressionError
    end

    context 'literal w/o indexing representation' do
      it 'should handle indexed header' do
        h = { name: 10, value: 'my-value', type: :noindex }
        wire = c.header(h)
        expect(wire.readbyte(0) & 0xf0).to eq 0x0
        expect(wire.readbyte(0) & 0x0f).to eq h[:name] + 1
        expect(d.header(wire)).to eq h
      end

      it 'should handle literal header' do
        h = { name: 'x-custom', value: 'my-value', type: :noindex }
        wire = c.header(h)
        expect(wire.readbyte(0) & 0xf0).to eq 0x0
        expect(wire.readbyte(0) & 0x0f).to eq 0
        expect(d.header(wire)).to eq h
      end
    end

    context 'literal w/ incremental indexing' do
      it 'should handle indexed header' do
        h = { name: 10, value: 'my-value', type: :incremental }
        wire = c.header(h)
        expect(wire.readbyte(0) & 0xc0).to eq 0x40
        expect(wire.readbyte(0) & 0x3f).to eq h[:name] + 1
        expect(d.header(wire)).to eq h
      end

      it 'should handle literal header' do
        h = { name: 'x-custom', value: 'my-value', type: :incremental }
        wire = c.header(h)
        expect(wire.readbyte(0) & 0xc0).to eq 0x40
        expect(wire.readbyte(0) & 0x3f).to eq 0
        expect(d.header(wire)).to eq h
      end
    end

    context 'literal never indexed' do
      it 'should handle indexed header' do
        h = { name: 10, value: 'my-value', type: :neverindexed }
        wire = c.header(h)
        expect(wire.readbyte(0) & 0xf0).to eq 0x10
        expect(wire.readbyte(0) & 0x0f).to eq h[:name] + 1
        expect(d.header(wire)).to eq h
      end

      it 'should handle literal header' do
        h = { name: 'x-custom', value: 'my-value', type: :neverindexed }
        wire = c.header(h)
        expect(wire.readbyte(0) & 0xf0).to eq 0x10
        expect(wire.readbyte(0) & 0x0f).to eq 0
        expect(d.header(wire)).to eq h
      end
    end
  end

  context 'shared compression context' do
    before(:each) { @cc = EncodingContext.new }

    it 'should be initialized with empty headers' do
      cc = EncodingContext.new
      expect(cc.table).to be_empty
    end

    context 'processing' do
      [
        ['no indexing', :noindex],
        ['never indexed', :neverindexed],
      ].each do |desc, type|
        context "#{desc}" do
          it 'should process indexed header with literal value' do
            original_table = @cc.table.dup

            emit = @cc.process(name: 4, value: '/path', type: type)
            expect(emit).to eq [':path', '/path']
            expect(@cc.table).to eq original_table
          end

          it 'should process literal header with literal value' do
            original_table = @cc.table.dup

            emit = @cc.process(name: 'x-custom', value: 'random', type: type)
            expect(emit).to eq ['x-custom', 'random']
            expect(@cc.table).to eq original_table
          end
        end
      end

      context 'incremental indexing' do
        it 'should process indexed header with literal value' do
          original_table = @cc.table.dup

          emit = @cc.process(name: 4, value: '/path', type: :incremental)
          expect(emit).to eq [':path', '/path']
          expect(@cc.table - original_table).to eq [[':path', '/path']]
        end

        it 'should process literal header with literal value' do
          original_table = @cc.table.dup

          @cc.process(name: 'x-custom', value: 'random', type: :incremental)
          expect(@cc.table - original_table).to eq [['x-custom', 'random']]
        end
      end

      context 'size bounds' do
        it 'should drop headers from end of table' do
          cc = EncodingContext.new(table_size: 2048)
          cc.instance_eval do
            add_to_table(['test1', '1' * 1024])
            add_to_table(['test2', '2' * 500])
          end

          original_table = cc.table.dup
          original_size = original_table.join.bytesize + original_table.size * 32

          cc.process(name: 'x-custom',
                     value: 'a' * (2048 - original_size),
                     type: :incremental)

          expect(cc.table.first[0]).to eq 'x-custom'
          expect(cc.table.size).to eq original_table.size # number of entries
        end
      end

      it 'should clear table if entry exceeds table size' do
        cc = EncodingContext.new(table_size: 2048)
        cc.instance_eval do
          add_to_table(['test1', '1' * 1024])
          add_to_table(['test2', '2' * 500])
        end

        h = { name: 'x-custom', value: 'a', index: 0, type: :incremental }
        e = { name: 'large', value: 'a' * 2048, index: 0 }

        cc.process(h)
        cc.process(e.merge(type: :incremental))
        expect(cc.table).to be_empty
      end

      it 'should shrink table if set smaller size' do
        cc = EncodingContext.new(table_size: 2048)
        cc.instance_eval do
          add_to_table(['test1', '1' * 1024])
          add_to_table(['test2', '2' * 500])
        end

        cc.process(type: :changetablesize, value: 1500)
        expect(cc.table.size).to be 1
        expect(cc.table.first[0]).to eq 'test2'
      end

      it 'should reject table size update if exceed limit' do
        cc = EncodingContext.new(table_size: 4096)

        expect { cc.process(type: :changetablesize, value: 150_000_000) }.to raise_error(CompressionError)
      end
    end

    context 'encode' do
      it 'downcases the field' do
        expect(EncodingContext.new.encode([['Content-Length', '5']]))
          .to eq(EncodingContext.new.encode([['content-length', '5']]))
      end

      it 'fills :path if empty' do
        expect(EncodingContext.new.encode([[':path', '']]))
          .to eq(EncodingContext.new.encode([[':path', '/']]))
      end
    end
  end

  spec_examples = [
    { title: 'D.3. Request Examples without Huffman',
      type: :request,
      table_size: 4096,
      huffman: :never,
      streams: [
        { wire: "8286 8441 0f77 7777 2e65 7861 6d70 6c65
                 2e63 6f6d",
          emitted: [
            [':method', 'GET'],
            [':scheme', 'http'],
            [':path', '/'],
            [':authority', 'www.example.com'],
          ],
          table: [
            [':authority', 'www.example.com'],
          ],
          table_size: 57,
        },
        { wire: '8286 84be 5808 6e6f 2d63 6163 6865',
          emitted: [
            [':method', 'GET'],
            [':scheme', 'http'],
            [':path', '/'],
            [':authority', 'www.example.com'],
            ['cache-control', 'no-cache'],
          ],
          table: [
            ['cache-control', 'no-cache'],
            [':authority', 'www.example.com'],
          ],
          table_size: 110,
        },
        { wire: "8287 85bf 400a 6375 7374 6f6d 2d6b 6579
                 0c63 7573 746f 6d2d 7661 6c75 65",
          emitted: [
            [':method', 'GET'],
            [':scheme', 'https'],
            [':path', '/index.html'],
            [':authority', 'www.example.com'],
            ['custom-key', 'custom-value'],
          ],
          table: [
            ['custom-key', 'custom-value'],
            ['cache-control', 'no-cache'],
            [':authority', 'www.example.com'],
          ],
          table_size: 164,
        },
      ],
    },
    { title: 'D.4.  Request Examples with Huffman',
      type: :request,
      table_size: 4096,
      huffman: :always,
      streams: [
        { wire: '8286 8441 8cf1 e3c2 e5f2 3a6b a0ab 90f4 ff',
          emitted: [
            [':method', 'GET'],
            [':scheme', 'http'],
            [':path', '/'],
            [':authority', 'www.example.com'],
          ],
          table: [
            [':authority', 'www.example.com'],
          ],
          table_size: 57,
        },
        { wire: '8286 84be 5886 a8eb 1064 9cbf',
          emitted: [
            [':method', 'GET'],
            [':scheme', 'http'],
            [':path', '/'],
            [':authority', 'www.example.com'],
            ['cache-control', 'no-cache'],
          ],
          table: [
            ['cache-control', 'no-cache'],
            [':authority', 'www.example.com'],
          ],
          table_size: 110,
        },
        { wire: "8287 85bf 4088 25a8 49e9 5ba9 7d7f 8925
                 a849 e95b b8e8 b4bf",
          emitted: [
            [':method', 'GET'],
            [':scheme', 'https'],
            [':path', '/index.html'],
            [':authority', 'www.example.com'],
            ['custom-key', 'custom-value'],
          ],
          table: [
            ['custom-key', 'custom-value'],
            ['cache-control', 'no-cache'],
            [':authority', 'www.example.com'],
          ],
          table_size: 164,
        },
      ],
    },
    { title: 'D.4.a.  Request Examples with Huffman - Client Handling of Improperly Ordered Headers',
      type: :request,
      table_size: 4096,
      huffman: :always,
      streams: [
        { wire: '8286 8441 8cf1 e3c2 e5f2 3a6b a0ab 90f4 ff',
          emitted: [
            [':method', 'GET'],
            [':scheme', 'http'],
            [':path', '/'],
            [':authority', 'www.example.com'],
          ],
          table: [
            [':authority', 'www.example.com'],
          ],
          table_size: 57,
        },
        { wire: '8286 84be 5886 a8eb 1064 9cbf',
          emitted: [
            [':method', 'GET'],
            [':scheme', 'http'],
            ['cache-control', 'no-cache'],
            [':path', '/'],
            [':authority', 'www.example.com'],
          ],
          table: [
            ['cache-control', 'no-cache'],
            [':authority', 'www.example.com'],
          ],
          table_size: 110,
        },
        { wire: "8287 85bf 4088 25a8 49e9 5ba9 7d7f 8925
                 a849 e95b b8e8 b4bf",
          emitted: [
            [':method', 'GET'],
            [':scheme', 'https'],
            ['custom-key', 'custom-value'],
            [':path', '/index.html'],
            [':authority', 'www.example.com'],
          ],
          table: [
            ['custom-key', 'custom-value'],
            ['cache-control', 'no-cache'],
            [':authority', 'www.example.com'],
          ],
          table_size: 164,
        },
      ],
    },
    { title: 'D.4.b.  Request Examples with Huffman - Server Handling of Improperly Ordered Headers',
      type: :request,
      bypass_encoder: true,
      table_size: 4096,
      huffman: :always,
      streams: [
        { wire: '8286408825a849e95ba97d7f8925a849e95bb8e8b4bf84418cf1e3c2e5f23a6ba0ab90f4ff',
          emitted: [
            [':method', 'GET'],
            [':scheme', 'http'],
            ['custom-key', 'custom-value'],
            [':path', '/'],
            [':authority', 'www.example.com'],
          ],
          table: [
            ['custom-key', 'custom-value'],
            [':authority', 'www.example.com'],
          ],
          table_size: 111,
          has_bad_headers: true,
        },
      ],
    },
    { title: 'D.5.  Response Examples without Huffman',
      type: :response,
      table_size: 256,
      huffman: :never,
      streams: [
        { wire: "4803 3330 3258 0770 7269 7661 7465 611d
                 4d6f 6e2c 2032 3120 4f63 7420 3230 3133
                 2032 303a 3133 3a32 3120 474d 546e 1768
                 7474 7073 3a2f 2f77 7777 2e65 7861 6d70
                 6c65 2e63 6f6d",
          emitted: [
            [':status', '302'],
            ['cache-control', 'private'],
            ['date', 'Mon, 21 Oct 2013 20:13:21 GMT'],
            ['location', 'https://www.example.com'],
          ],
          table: [
            ['location', 'https://www.example.com'],
            ['date', 'Mon, 21 Oct 2013 20:13:21 GMT'],
            ['cache-control', 'private'],
            [':status', '302'],
          ],
          table_size: 222,
        },
        { wire: '4803 3330 37c1 c0bf',
          emitted: [
            [':status', '307'],
            ['cache-control', 'private'],
            ['date', 'Mon, 21 Oct 2013 20:13:21 GMT'],
            ['location', 'https://www.example.com'],
          ],
          table: [
            [':status', '307'],
            ['location', 'https://www.example.com'],
            ['date', 'Mon, 21 Oct 2013 20:13:21 GMT'],
            ['cache-control', 'private'],
          ],
          table_size: 222,
        },
        { wire: "88c1 611d 4d6f 6e2c 2032 3120 4f63 7420
                 3230 3133 2032 303a 3133 3a32 3220 474d
                 54c0 5a04 677a 6970 7738 666f 6f3d 4153
                 444a 4b48 514b 425a 584f 5157 454f 5049
                 5541 5851 5745 4f49 553b 206d 6178 2d61
                 6765 3d33 3630 303b 2076 6572 7369 6f6e
                 3d31",
          emitted: [
            [':status', '200'],
            ['cache-control', 'private'],
            ['date', 'Mon, 21 Oct 2013 20:13:22 GMT'],
            ['location', 'https://www.example.com'],
            ['content-encoding', 'gzip'],
            ['set-cookie', 'foo=ASDJKHQKBZXOQWEOPIUAXQWEOIU; max-age=3600; version=1'],
          ],
          table: [
            ['set-cookie', 'foo=ASDJKHQKBZXOQWEOPIUAXQWEOIU; max-age=3600; version=1'],
            ['content-encoding', 'gzip'],
            ['date', 'Mon, 21 Oct 2013 20:13:22 GMT'],
          ],
          table_size: 215,
        },
      ],
    },
    { title: 'D.6.  Response Examples with Huffman',
      type: :response,
      table_size: 256,
      huffman: :always,
      streams: [
        { wire: "4882 6402 5885 aec3 771a 4b61 96d0 7abe
                 9410 54d4 44a8 2005 9504 0b81 66e0 82a6
                 2d1b ff6e 919d 29ad 1718 63c7 8f0b 97c8
                 e9ae 82ae 43d3",
          emitted: [
            [':status', '302'],
            ['cache-control', 'private'],
            ['date', 'Mon, 21 Oct 2013 20:13:21 GMT'],
            ['location', 'https://www.example.com'],
          ],
          table: [
            ['location', 'https://www.example.com'],
            ['date', 'Mon, 21 Oct 2013 20:13:21 GMT'],
            ['cache-control', 'private'],
            [':status', '302'],
          ],
          table_size: 222,
        },
        { wire: '4883 640e ffc1 c0bf',
          emitted: [
            [':status', '307'],
            ['cache-control', 'private'],
            ['date', 'Mon, 21 Oct 2013 20:13:21 GMT'],
            ['location', 'https://www.example.com'],
          ],
          table: [
            [':status', '307'],
            ['location', 'https://www.example.com'],
            ['date', 'Mon, 21 Oct 2013 20:13:21 GMT'],
            ['cache-control', 'private'],
          ],
          table_size: 222,
        },
        { wire: "88c1 6196 d07a be94 1054 d444 a820 0595
                 040b 8166 e084 a62d 1bff c05a 839b d9ab
                 77ad 94e7 821d d7f2 e6c7 b335 dfdf cd5b
                 3960 d5af 2708 7f36 72c1 ab27 0fb5 291f
                 9587 3160 65c0 03ed 4ee5 b106 3d50 07",
          emitted: [
            [':status', '200'],
            ['cache-control', 'private'],
            ['date', 'Mon, 21 Oct 2013 20:13:22 GMT'],
            ['location', 'https://www.example.com'],
            ['content-encoding', 'gzip'],
            ['set-cookie', 'foo=ASDJKHQKBZXOQWEOPIUAXQWEOIU; max-age=3600; version=1'],
          ],
          table: [
            ['set-cookie', 'foo=ASDJKHQKBZXOQWEOPIUAXQWEOIU; max-age=3600; version=1'],
            ['content-encoding', 'gzip'],
            ['date', 'Mon, 21 Oct 2013 20:13:22 GMT'],
          ],
          table_size: 215,
        },
      ],
    },
    { title: 'D.6.a.  Response Examples with Huffman - dynamic table size updates should not trigger exceptions',
      type: :response,
      table_size: 4096,
      huffman: :always,
      bypass_encoder: true,
      streams: [
        { wire: '2088 7689 aa63 55e5 80ae 16d7 17',
          emitted: [
            [':status', '200'],
            ['server', 'nginx/1.15.2'],
          ],
          table: [],
          table_size: 0,
        },
      ],
    },
  ]

  context 'decode' do
    spec_examples.each do |ex|
      context "spec example #{ex[:title]}" do
        ex[:streams].size.times do |nth|
          context "request #{nth + 1}" do
            before { @dc = Decompressor.new(table_size: ex[:table_size]) }
            before do
              (0...nth).each do |i|
                bytes = [ex[:streams][i][:wire].delete(" \n")].pack('H*')
                if ex[:streams][i][:has_bad_headers]
                  expect { @dc.decode(HTTP2::Buffer.new(bytes)) }.to raise_error ProtocolError
                else
                  @dc.decode(HTTP2::Buffer.new(bytes))
                end
              end
            end
            if ex[:streams][nth][:has_bad_headers]
              it 'should raise CompressionError' do
                bytes = [ex[:streams][nth][:wire].delete(" \n")].pack('H*')
                expect { @dc.decode(HTTP2::Buffer.new(bytes)) }.to raise_error ProtocolError
              end
            else
              subject do
                bytes = [ex[:streams][nth][:wire].delete(" \n")].pack('H*')
                @emitted = @dc.decode(HTTP2::Buffer.new(bytes))
              end
              it 'should emit expected headers' do
                subject
                # partitioned compare
                pseudo_headers, headers = ex[:streams][nth][:emitted].partition { |f, _| f.start_with? ':' }
                partitioned_headers = pseudo_headers + headers
                expect(@emitted).to eq partitioned_headers
              end
              it 'should update header table' do
                subject
                expect(@dc.instance_eval { @cc.table }).to eq ex[:streams][nth][:table]
              end
              it 'should compute header table size' do
                subject
                expect(@dc.instance_eval { @cc.current_table_size }).to eq ex[:streams][nth][:table_size]
              end
            end
          end
        end
      end
    end
  end

  context 'encode' do
    spec_examples.each do |ex|
      next if ex[:bypass_encoder]
      context "spec example #{ex[:title]}" do
        ex[:streams].size.times do |nth|
          context "request #{nth + 1}" do
            before do
              @cc = Compressor.new(table_size: ex[:table_size],
                                   huffman: ex[:huffman])
            end
            before do
              (0...nth).each do |i|
                if ex[:streams][i][:has_bad_headers]
                  @cc.encode(ex[:streams][i][:emitted], ensure_proper_ordering: false)
                else
                  @cc.encode(ex[:streams][i][:emitted])
                end
              end
            end
            subject do
              if ex[:streams][nth][:has_bad_headers]
                @cc.encode(ex[:streams][nth][:emitted], ensure_proper_ordering: false)
              else
                @cc.encode(ex[:streams][nth][:emitted])
              end
            end
            it 'should emit expected bytes on wire' do
              puts subject.unpack('H*').first
              expect(subject.unpack('H*').first).to eq ex[:streams][nth][:wire].delete(" \n")
            end
            unless ex[:streams][nth][:has_bad_headers]
              it 'should update header table' do
                subject
                expect(@cc.instance_eval { @cc.table }).to eq ex[:streams][nth][:table]
              end
              it 'should compute header table size' do
                subject
                expect(@cc.instance_eval { @cc.current_table_size }).to eq ex[:streams][nth][:table_size]
              end
            end
          end
        end
      end
    end
  end
end
