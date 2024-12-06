# frozen_string_literal: true

# rubocop:disable Lint/ConstantDefinitionInBlock, Lint/EmptyClass

require 'spec_helper'

RSpec.describe 'AmazingPrint' do
  describe 'Misc' do
    it 'handle weird objects that return nil on inspect' do
      weird = Class.new do
        def inspect
          nil
        end
      end
      expect(weird.new.ai(plain: true)).to eq('')
    end

    it 'handle frozen object.inspect' do
      weird = Class.new do
        def inspect
          'ice'
        end
      end
      expect(weird.new.ai(plain: false)).to eq('ice')
    end

    # See https://github.com/awesome-print/awesome_print/issues/35
    it 'handle array grep when pattern contains / chapacter' do
      hash = { '1/x' => 1, '2//x' => :'2' }
      grepped = hash.keys.sort.grep(%r{^(\d+)/}) { Regexp.last_match(1) }
      expect(grepped.ai(plain: true, multiline: false)).to eq('[ "1", "2" ]')
    end

    # See https://github.com/awesome-print/awesome_print/issues/85
    it "handle array grep when a method is defined in C and thus doesn't have a binding" do
      arr = (0..6).to_a
      grepped = arr.grep(1..4, &:succ)
      expect(grepped.ai(plain: true, multiline: false)).to eq('[ 2, 3, 4, 5 ]')
    end

    it 'returns value passed as a parameter' do
      object = rand
      allow(self).to receive(:puts)
      expect(ap(object)).to eq(object)
    end

    # Require different file name this time (lib/ap.rb vs. lib/amazing_print).
    it "several require 'amazing_print' should do no harm" do
      require File.expand_path("#{File.dirname(__FILE__)}/../lib/ap")
      expect { rand.ai }.not_to raise_error
    end

    it 'format ENV as hash' do
      expect(ENV.ai(plain: true)).to eq(ENV.to_hash.ai(plain: true))
      expect(ENV.ai).to eq(ENV.to_hash.ai)
    end

    # See https://github.com/awesome-print/awesome_print/issues/134
    it 'IPAddr workaround' do
      require 'ipaddr'
      ipaddr = IPAddr.new('3ffe:505:2::1')
      expect(ipaddr.ai).to eq('#<IPAddr: IPv6:3ffe:0505:0002:0000:0000:0000:0000:0001/ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff>')
    end

    # See https://github.com/awesome-print/awesome_print/issues/139
    it 'Object that overrides == and expects the :id method' do
      weird = Class.new do
        # Raises NoMethodError: undefined method `id' when "other" is nil or ENV.
        def ==(other)
          id == other.id
        end
        alias_method :eql?, :==
      end
      expect { weird.new.ai }.not_to raise_error
    end
  end

  #------------------------------------------------------------------------------
  describe 'HTML output' do
    it 'wraps ap output with plain <pre> tag' do
      markup = rand
      expect(markup.ai(html: true, plain: true)).to eq("<pre>#{markup}</pre>")
    end

    it 'wraps ap output with <pre> tag with colorized <kbd>' do
      markup = rand
      expect(markup.ai(html: true)).to eq(%(<pre><kbd style="color:blue">#{markup}</kbd></pre>))
    end

    it 'wraps multiline ap output with <pre> tag with colorized <kbd>' do
      markup = [1, :two, 'three']
      expect(markup.ai(html: true)).to eq <<~EOS.strip
        <pre>[
            <kbd style="color:white">[0] </kbd><kbd style="color:blue">1</kbd>,
            <kbd style="color:white">[1] </kbd><kbd style="color:darkcyan">:two</kbd>,
            <kbd style="color:white">[2] </kbd><kbd style="color:brown">&quot;three&quot;</kbd>
        ]</pre>
      EOS
    end

    it 'wraps hash ap output with only an outer <pre> tag' do
      markup = [{ 'hello' => 'world' }]
      expect(markup.ai(html: true)).to eq <<~EOS.strip
        <pre>[
            <kbd style="color:white">[0] </kbd>{
                <kbd style="color:brown">&quot;hello&quot;</kbd><kbd style="color:slategray"> =&gt; </kbd><kbd style="color:brown">&quot;world&quot;</kbd>
            }
        ]</pre>
      EOS
    end

    it 'encodes HTML entities (plain)' do
      markup = ' &<hello>'
      expect(markup.ai(html: true, plain: true)).to eq('<pre>&quot; &amp;&lt;hello&gt;&quot;</pre>')
    end

    it 'encodes HTML entities (color)' do
      markup = ' &<hello>'
      expect(markup.ai(html: true)).to eq('<pre><kbd style="color:brown">&quot; &amp;&lt;hello&gt;&quot;</kbd></pre>')
    end
  end

  #------------------------------------------------------------------------------
  describe 'AmazingPrint.defaults' do
    after do
      AmazingPrint.defaults = nil
    end

    # See https://github.com/awesome-print/awesome_print/issues/98
    it 'properlies merge the defaults' do
      AmazingPrint.defaults = { indent: -2, sort_keys: true }
      hash = { [0, 0, 255] => :yellow, :red => 'rgb(255, 0, 0)', 'magenta' => 'rgb(255, 0, 255)' }
      out = hash.ai(plain: true)
      expect(out).to eq <<~EOS.strip
        {
          [ 0, 0, 255 ] => :yellow,
          "magenta"     => "rgb(255, 0, 255)",
          :red          => "rgb(255, 0, 0)"
        }
      EOS
    end
  end

  #------------------------------------------------------------------------------
  describe 'Console' do
    it 'detects IRB' do
      class IRB; end
      ENV.delete('RAILS_ENV')
      expect(AmazingPrint.console?).to be(true)
      expect(AmazingPrint.rails_console?).to be(false)
      Object.instance_eval { remove_const :IRB }
    end

    it 'detects Pry' do
      class Pry; end
      ENV.delete('RAILS_ENV')
      expect(AmazingPrint.console?).to be(true)
      expect(AmazingPrint.rails_console?).to be(false)
      Object.instance_eval { remove_const :Pry }
    end

    it 'detects Rails::Console' do
      class IRB; end

      module Rails; class Console; end; end
      expect(AmazingPrint.console?).to be(true)
      expect(AmazingPrint.rails_console?).to be(true)
      Object.instance_eval { remove_const :IRB }
      Object.instance_eval { remove_const :Rails }
    end

    it "detects ENV['RAILS_ENV']" do
      class Pry; end
      ENV['RAILS_ENV'] = 'development'
      expect(AmazingPrint.console?).to be(true)
      expect(AmazingPrint.rails_console?).to be(true)
      Object.instance_eval { remove_const :Pry }
    end

    it 'returns the actual object when *not* running under console' do
      expect(capture! { ap([1, 2, 3]) }).to eq([1, 2, 3])
      expect(capture! { ap({ a: 1 }) }).to eq({ a: 1 })
    end

    it 'returns nil when running under console' do
      class IRB; end
      expect(capture! { ap([1, 2, 3]) }).to be_nil
      expect(capture! { ap({ a: 1 }) }).to be_nil
      Object.instance_eval { remove_const :IRB }
    end

    it 'handles NoMethodError on IRB implicit #ai' do
      module IRB; class Irb; end; end
      irb_context = double('irb_context', last_value: BasicObject.new)
      IRB.define_singleton_method :version, -> { 'test_version' }
      irb = IRB::Irb.new
      irb.instance_eval { @context = irb_context }
      AmazingPrint.irb!
      expect(irb).to receive(:puts).with("(Object doesn't support #ai)")
      expect { irb.output_value }.not_to raise_error
      Object.instance_eval { remove_const :IRB }
    end
  end
end

# rubocop:enable Lint/ConstantDefinitionInBlock, Lint/EmptyClass
