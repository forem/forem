# frozen_string_literal: true

# rubocop:disable Lint/ConstantDefinitionInBlock

require 'spec_helper'
require 'bigdecimal'
require 'set'

RSpec.describe 'AmazingPrint' do
  describe 'Array' do
    before do
      @arr = [1, :two, 'three', [nil, [true, false]]]
    end

    it 'empty array' do
      expect([].ai).to eq('[]')
    end

    it 'plain multiline' do
      expect(@arr.ai(plain: true)).to eq <<~EOS.strip
        [
            [0] 1,
            [1] :two,
            [2] "three",
            [3] [
                [0] nil,
                [1] [
                    [0] true,
                    [1] false
                ]
            ]
        ]
      EOS
    end

    it 'plain multiline without index' do
      expect(@arr.ai(plain: true, index: false)).to eq <<~EOS.strip
        [
            1,
            :two,
            "three",
            [
                nil,
                [
                    true,
                    false
                ]
            ]
        ]
      EOS
    end

    it 'plain multiline indented' do
      expect(@arr.ai(plain: true, indent: 2)).to eq <<~EOS.strip
        [
          [0] 1,
          [1] :two,
          [2] "three",
          [3] [
            [0] nil,
            [1] [
              [0] true,
              [1] false
            ]
          ]
        ]
      EOS
    end

    it 'plain multiline indented without index' do
      expect(@arr.ai(plain: true, indent: 2, index: false)).to eq <<~EOS.strip
        [
          1,
          :two,
          "three",
          [
            nil,
            [
              true,
              false
            ]
          ]
        ]
      EOS
    end

    it 'plain single line' do
      expect(@arr.ai(plain: true, multiline: false)).to eq('[ 1, :two, "three", [ nil, [ true, false ] ] ]')
    end

    it 'colored multiline (default)' do
      expect(@arr.ai).to eq <<~EOS.strip
        [
            \e[1;37m[0] \e[0m\e[1;34m1\e[0m,
            \e[1;37m[1] \e[0m\e[0;36m:two\e[0m,
            \e[1;37m[2] \e[0m\e[0;33m"three"\e[0m,
            \e[1;37m[3] \e[0m[
                \e[1;37m[0] \e[0m\e[1;31mnil\e[0m,
                \e[1;37m[1] \e[0m[
                    \e[1;37m[0] \e[0m\e[1;32mtrue\e[0m,
                    \e[1;37m[1] \e[0m\e[1;31mfalse\e[0m
                ]
            ]
        ]
      EOS
    end

    it 'colored multiline indented' do
      expect(@arr.ai(indent: 8)).to eq <<~EOS.strip
        [
                \e[1;37m[0] \e[0m\e[1;34m1\e[0m,
                \e[1;37m[1] \e[0m\e[0;36m:two\e[0m,
                \e[1;37m[2] \e[0m\e[0;33m"three"\e[0m,
                \e[1;37m[3] \e[0m[
                        \e[1;37m[0] \e[0m\e[1;31mnil\e[0m,
                        \e[1;37m[1] \e[0m[
                                \e[1;37m[0] \e[0m\e[1;32mtrue\e[0m,
                                \e[1;37m[1] \e[0m\e[1;31mfalse\e[0m
                        ]
                ]
        ]
      EOS
    end

    it 'colored single line' do
      expect(@arr.ai(multiline: false)).to eq("[ \e[1;34m1\e[0m, \e[0;36m:two\e[0m, \e[0;33m\"three\"\e[0m, [ \e[1;31mnil\e[0m, [ \e[1;32mtrue\e[0m, \e[1;31mfalse\e[0m ] ] ]")
    end
  end

  #------------------------------------------------------------------------------
  describe 'Nested Array' do
    before do
      @arr = [1, 2]
      @arr << @arr
    end

    it 'plain multiline' do
      expect(@arr.ai(plain: true)).to eq <<~EOS.strip
        [
            [0] 1,
            [1] 2,
            [2] [...]
        ]
      EOS
    end

    it 'plain multiline without index' do
      expect(@arr.ai(plain: true, index: false)).to eq <<~EOS.strip
        [
            1,
            2,
            [...]
        ]
      EOS
    end

    it 'plain single line' do
      expect(@arr.ai(plain: true, multiline: false)).to eq('[ 1, 2, [...] ]')
    end
  end

  #------------------------------------------------------------------------------
  describe 'Limited Output Array' do
    before do
      @arr = (1..1000).to_a
    end

    it 'plain limited output large' do
      expect(@arr.ai(plain: true, limit: true)).to eq <<~EOS.strip
        [
            [  0] 1,
            [  1] 2,
            [  2] 3,
            [  3] .. [996],
            [997] 998,
            [998] 999,
            [999] 1000
        ]
      EOS
    end

    it 'plain limited output small' do
      @arr = @arr[0..3]
      expect(@arr.ai(plain: true, limit: true)).to eq <<~EOS.strip
        [
            [0] 1,
            [1] 2,
            [2] 3,
            [3] 4
        ]
      EOS
    end

    it 'plain limited output with 10 lines' do
      expect(@arr.ai(plain: true, limit: 10)).to eq <<~EOS.strip
        [
            [  0] 1,
            [  1] 2,
            [  2] 3,
            [  3] 4,
            [  4] 5,
            [  5] .. [995],
            [996] 997,
            [997] 998,
            [998] 999,
            [999] 1000
        ]
      EOS
    end

    it 'plain limited output with 11 lines' do
      expect(@arr.ai(plain: true, limit: 11)).to eq <<~EOS.strip
        [
            [  0] 1,
            [  1] 2,
            [  2] 3,
            [  3] 4,
            [  4] 5,
            [  5] .. [994],
            [995] 996,
            [996] 997,
            [997] 998,
            [998] 999,
            [999] 1000
        ]
      EOS
    end
  end

  #------------------------------------------------------------------------------
  describe 'Limited Output Hash' do
    before do
      @hash = ('a'..'z').inject({}) { |h, v| h.merge({ v => v.to_sym }) }
    end

    it 'plain limited output' do
      expect(@hash.ai(sort_keys: true, plain: true, limit: true)).to eq <<~EOS.strip
        {
            "a" => :a,
            "b" => :b,
            "c" => :c,
            "d" => :d .. "w" => :w,
            "x" => :x,
            "y" => :y,
            "z" => :z
        }
      EOS
    end
  end

  #------------------------------------------------------------------------------
  describe 'Hash' do
    before do
      @hash = { 1 => { sym: { 'str' => { [1, 2, 3] => { { k: :v } => Hash } } } } }
    end

    it 'empty hash' do
      expect({}.ai).to eq('{}')
    end

    it 'plain multiline' do
      expect(@hash.ai(plain: true)).to eq <<~EOS.strip
        {
            1 => {
                :sym => {
                    "str" => {
                        [ 1, 2, 3 ] => {
                            { :k => :v } => Hash < Object
                        }
                    }
                }
            }
        }
      EOS
    end

    it 'new hash syntax' do
      expect(@hash.ai(plain: true, ruby19_syntax: true)).to eq <<~EOS.strip
        {
            1 => {
                sym: {
                    "str" => {
                        [ 1, 2, 3 ] => {
                            { k: :v } => Hash < Object
                        }
                    }
                }
            }
        }
      EOS
    end

    it 'plain multiline indented' do
      expect(@hash.ai(plain: true, indent: 1)).to eq <<~EOS.strip
        {
         1 => {
          :sym => {
           "str" => {
            [ 1, 2, 3 ] => {
             { :k => :v } => Hash < Object
            }
           }
          }
         }
        }
      EOS
    end

    it 'plain single line' do
      expect(@hash.ai(plain: true,
                      multiline: false)).to eq('{ 1 => { :sym => { "str" => { [ 1, 2, 3 ] => { { :k => :v } => Hash < Object } } } } }')
    end

    it 'colored multiline (default)' do
      expect(@hash.ai).to eq <<~EOS.strip
        {
            \e[1;34m1\e[0m\e[0;37m => \e[0m{
                \e[0;36m:sym\e[0m\e[0;37m => \e[0m{
                    \e[0;33m"str"\e[0m\e[0;37m => \e[0m{
                        [ \e[1;34m1\e[0m, \e[1;34m2\e[0m, \e[1;34m3\e[0m ]\e[0;37m => \e[0m{
                            { \e[0;36m:k\e[0m\e[0;37m => \e[0m\e[0;36m:v\e[0m }\e[0;37m => \e[0m\e[1;33mHash < Object\e[0m
                        }
                    }
                }
            }
        }
      EOS
    end

    it 'colored with new hash syntax' do
      expect(@hash.ai(ruby19_syntax: true)).to eq <<~EOS.strip
        {
            \e[1;34m1\e[0m\e[0;37m => \e[0m{
                \e[0;36m:sym\e[0m\e[0;37m => \e[0m{
                    \e[0;33m"str"\e[0m\e[0;37m => \e[0m{
                        [ \e[1;34m1\e[0m, \e[1;34m2\e[0m, \e[1;34m3\e[0m ]\e[0;37m => \e[0m{
                            { \e[0;36m:k\e[0m\e[0;37m => \e[0m\e[0;36m:v\e[0m }\e[0;37m => \e[0m\e[1;33mHash < Object\e[0m
                        }
                    }
                }
            }
        }
      EOS
    end

    it 'colored multiline indented' do
      expect(@hash.ai(indent: 2)).to eq <<~EOS.strip
        {
          \e[1;34m1\e[0m\e[0;37m => \e[0m{
            \e[0;36m:sym\e[0m\e[0;37m => \e[0m{
              \e[0;33m"str"\e[0m\e[0;37m => \e[0m{
                [ \e[1;34m1\e[0m, \e[1;34m2\e[0m, \e[1;34m3\e[0m ]\e[0;37m => \e[0m{
                  { \e[0;36m:k\e[0m\e[0;37m => \e[0m\e[0;36m:v\e[0m }\e[0;37m => \e[0m\e[1;33mHash < Object\e[0m
                }
              }
            }
          }
        }
      EOS
    end

    it 'colored single line' do
      puts @hash.ai(multiline: false)
      expect(@hash.ai(multiline: false)).to eq(
        "{ \e[1;34m1\e[0m\e[0;37m => \e[0m{ \e[0;36m:sym\e[0m\e[0;37m => \e[0m{ \e[0;33m\"str\"\e[0m\e[0;37m => \e[0m{ [ \e[1;34m1\e[0m, \e[1;34m2\e[0m, \e[1;34m3\e[0m ]\e[0;37m => \e[0m{ { \e[0;36m:k\e[0m\e[0;37m => \e[0m\e[0;36m:v\e[0m }\e[0;37m => \e[0m\e[1;33mHash < Object\e[0m } } } } }" # rubocop:disable Layout/LineLength
      )
    end
  end

  #------------------------------------------------------------------------------
  describe 'Nested Hash' do
    before do
      @hash = {}
      @hash[:a] = @hash
    end

    it 'plain multiline' do
      expect(@hash.ai(plain: true)).to eq <<~EOS.strip
        {
            :a => {...}
        }
      EOS
    end

    it 'plain single line' do
      expect(@hash.ai(plain: true, multiline: false)).to eq('{ :a => {...} }')
    end
  end

  #------------------------------------------------------------------------------
  describe 'Hash with several keys' do
    before do
      @hash = { 'b' => 'b', :a => 'a', :z => 'z', 'alpha' => 'alpha' }
    end

    it 'plain multiline' do
      out = @hash.ai(plain: true)
      expect(out).to eq <<~EOS.strip
        {
                "b" => "b",
                 :a => "a",
                 :z => "z",
            "alpha" => "alpha"
        }
      EOS
    end

    it 'plain multiline with sorted keys' do
      expect(@hash.ai(plain: true, sort_keys: true)).to eq <<~EOS.strip
        {
                 :a => "a",
            "alpha" => "alpha",
                "b" => "b",
                 :z => "z"
        }
      EOS
    end
  end

  #------------------------------------------------------------------------------
  describe 'Negative options[:indent]' do
    #
    # With Ruby < 1.9 the order of hash keys is not defined so we can't
    # reliably compare the output string.
    #
    it 'hash keys must be left aligned' do
      hash = { [0, 0, 255] => :yellow, :red => 'rgb(255, 0, 0)', 'magenta' => 'rgb(255, 0, 255)' }
      out = hash.ai(plain: true, indent: -4, sort_keys: true)
      expect(out).to eq <<~EOS.strip
        {
            [ 0, 0, 255 ] => :yellow,
            "magenta"     => "rgb(255, 0, 255)",
            :red          => "rgb(255, 0, 0)"
        }
      EOS
    end

    it 'nested hash keys should be indented (array of hashes)' do
      arr = [{ a: 1, bb: 22, ccc: 333 }, { 1 => :a, 22 => :bb, 333 => :ccc }]
      out = arr.ai(plain: true, indent: -4, sort_keys: true)
      expect(out).to eq <<~EOS.strip
        [
            [0] {
                :a   => 1,
                :bb  => 22,
                :ccc => 333
            },
            [1] {
                1   => :a,
                22  => :bb,
                333 => :ccc
            }
        ]
      EOS
    end

    it 'nested hash keys should be indented (hash of hashes)' do
      arr = { first: { a: 1, bb: 22, ccc: 333 }, second: { 1 => :a, 22 => :bb, 333 => :ccc } }
      out = arr.ai(plain: true, indent: -4, sort_keys: true)
      expect(out).to eq <<~EOS.strip
        {
            :first  => {
                :a   => 1,
                :bb  => 22,
                :ccc => 333
            },
            :second => {
                1   => :a,
                22  => :bb,
                333 => :ccc
            }
        }
      EOS
    end
  end

  #
  # With Ruby 1.9 syntax
  #
  it 'hash keys must be left aligned' do
    hash = { [0, 0, 255] => :yellow, :bloodiest_red => 'rgb(255, 0, 0)', 'magenta' => 'rgb(255, 0, 255)' }
    out = hash.ai(plain: true, indent: -2, ruby19_syntax: true, sort_keys: true)
    expect(out).to eq <<~EOS.strip
      {
        [ 0, 0, 255 ]  => :yellow,
        bloodiest_red: "rgb(255, 0, 0)",
        "magenta"      => "rgb(255, 0, 255)"
      }
    EOS
  end

  #------------------------------------------------------------------------------
  describe 'Class' do
    it 'shows superclass (plain)' do
      expect(self.class.ai(plain: true)).to eq("#{self.class} < #{self.class.superclass}")
    end

    it 'shows superclass (color)' do
      expect(self.class.ai).to eq(AmazingPrint::Colors.yellow("#{self.class} < #{self.class.superclass}"))
    end
  end

  #------------------------------------------------------------------------------
  describe 'File' do
    it 'displays a file (plain)', :unix do
      File.open(__FILE__, 'r') do |f|
        expect(f.ai(plain: true)).to eq("#{f.inspect}\n" + `ls -alF #{f.path}`.chop)
      end
    end

    it 'displays a file (plain) akin to powershell Get-ChildItem', :mswin do
      File.open(__FILE__, 'r') do |f|
        expect(f.ai(plain: true)).to eq("#{f.inspect}\n" + AmazingPrint::Formatters::GetChildItem.new(f.path).to_s)
      end
    end
  end

  #------------------------------------------------------------------------------
  describe 'Dir' do
    it 'displays a direcory (plain)', :unix do
      Dir.open(File.dirname(__FILE__)) do |d|
        expect(d.ai(plain: true)).to eq("#{d.inspect}\n" + `ls -alF #{d.path}`.chop)
      end
    end

    it 'displays a directory (plain) akin to powershell Get-ChildItem', :mswin do
      Dir.open(File.dirname(__FILE__)) do |d|
        expect(d.ai(plain: true)).to eq("#{d.inspect}\n" + AmazingPrint::Formatters::GetChildItem.new(d.path).to_s)
      end
    end
  end

  #------------------------------------------------------------------------------
  describe 'BigDecimal and Rational' do
    it 'presents BigDecimal object with arbitrary precision' do
      big = BigDecimal('201020102010201020102010201020102010.4')
      expect(big.ai(plain: true)).to eq('201020102010201020102010201020102010.4')
    end

    it 'presents Rational object with arbitrary precision' do
      rat = Rational(201_020_102_010_201_020_102_010_201_020_102_010, 2)
      out = rat.ai(plain: true)
      expect(out).to eq('100510051005100510051005100510051005/1')
    end
  end

  #------------------------------------------------------------------------------
  describe 'Utility methods' do
    it 'merges options' do
      ap = AmazingPrint::Inspector.new
      ap.send(:merge_options!, { color: { array: :black }, indent: 0 })
      options = ap.instance_variable_get('@options')
      expect(options[:color][:array]).to eq(:black)
      expect(options[:indent]).to eq(0)
    end
  end

  #------------------------------------------------------------------------------
  describe 'Set' do
    before do
      @arr = [1, :two, 'three']
      @set = Set.new(@arr)
    end

    it 'empty set' do
      expect(Set.new.ai).to eq([].ai)
    end

    it 'plain multiline' do
      expect(@set.ai(plain: true)).to eq(@arr.ai(plain: true))
    end

    it 'plain multiline indented' do
      expect(@set.ai(plain: true, indent: 1)).to eq(@arr.ai(plain: true, indent: 1))
    end

    it 'plain single line' do
      expect(@set.ai(plain: true, multiline: false)).to eq(@arr.ai(plain: true, multiline: false))
    end

    it 'colored multiline (default)' do
      expect(@set.ai).to eq(@arr.ai)
    end
  end

  #------------------------------------------------------------------------------
  describe 'Struct' do
    before do
      @struct = if defined?(Struct::SimpleStruct)
                  Struct::SimpleStruct.new
                else
                  Struct.new('SimpleStruct', :name, :address).new
                end
      @struct.name = 'Herman Munster'
      @struct.address = '1313 Mockingbird Lane'
    end

    it 'empty struct' do
      expect(Struct.new('EmptyStruct').ai).to eq("\e[1;33mStruct::EmptyStruct < Struct\e[0m")
    end

    it 'plain multiline' do
      s1 = <<-EOS.strip
    address = "1313 Mockingbird Lane",
    name = "Herman Munster"
      EOS
      s2 = <<-EOS.strip
    name = "Herman Munster",
    address = "1313 Mockingbird Lane"
      EOS
      expect(@struct.ai(plain: true)).to satisfy { |out| out.match(s1) || out.match(s2) }
    end

    it 'plain multiline indented' do
      s1 = <<-EOS.strip
 address = "1313 Mockingbird Lane",
 name = "Herman Munster"
      EOS
      s2 = <<-EOS.strip
 name = "Herman Munster",
 address = "1313 Mockingbird Lane"
      EOS
      expect(@struct.ai(plain: true, indent: 1)).to satisfy { |out| out.match(s1) || out.match(s2) }
    end

    it 'plain single line' do
      s1 = 'address = "1313 Mockingbird Lane", name = "Herman Munster"'
      s2 = 'name = "Herman Munster", address = "1313 Mockingbird Lane"'
      expect(@struct.ai(plain: true, multiline: false)).to satisfy { |out| out.match(s1) || out.match(s2) }
    end

    it 'colored multiline (default)' do
      s1 = <<-EOS.strip
    address\e[0;37m = \e[0m\e[0;33m"1313 Mockingbird Lane"\e[0m,
    name\e[0;37m = \e[0m\e[0;33m"Herman Munster"\e[0m
      EOS
      s2 = <<-EOS.strip
    name\e[0;37m = \e[0m\e[0;33m"Herman Munster"\e[0m,
    address\e[0;37m = \e[0m\e[0;33m"1313 Mockingbird Lane"\e[0m
      EOS
      expect(@struct.ai).to satisfy { |out| out.include?(s1) || out.include?(s2) }
    end
  end

  #------------------------------------------------------------------------------
  describe 'Inherited from standard Ruby classes' do
    after do
      Object.instance_eval { remove_const :My } if defined?(My)
    end

    it 'inherited from Array should be displayed as Array' do
      class My < Array; end

      my = My.new([1, :two, 'three', [nil, [true, false]]])
      expect(my.ai(plain: true)).to eq <<~EOS.strip
        [
            [0] 1,
            [1] :two,
            [2] "three",
            [3] [
                [0] nil,
                [1] [
                    [0] true,
                    [1] false
                ]
            ]
        ]
      EOS
    end

    it 'inherited from Hash should be displayed as Hash' do
      class My < Hash; end

      my = My[{ 1 => { sym: { 'str' => { [1, 2, 3] => { { k: :v } => Hash } } } } }]
      expect(my.ai(plain: true)).to eq <<~EOS.strip
        {
            1 => {
                :sym => {
                    "str" => {
                        [ 1, 2, 3 ] => {
                            { :k => :v } => Hash < Object
                        }
                    }
                }
            }
        }
      EOS
    end

    it 'inherited from File should be displayed as File', :unix do
      class My < File; end

      my = begin
        File.new('/dev/null')
      rescue StandardError
        File.new('nul')
      end
      expect(my.ai(plain: true)).to eq("#{my.inspect}\n" + `ls -alF #{my.path}`.chop)
    end

    it 'inherited from File should be displayed as File', :mswin do
      class My < File; end
      my = My.new('nul') # it's /dev/null in Windows
      expect(my.ai(plain: true)).to eq("#{my.inspect}\n" + AmazingPrint::Formatters::GetChildItem.new(my.path).to_s)
    end

    it 'inherited from Dir should be displayed as Dir', :unix do
      class My < Dir; end

      require 'tmpdir'
      my = My.new(Dir.tmpdir)
      expect(my.ai(plain: true)).to eq("#{my.inspect}\n" + `ls -alF #{my.path}`.chop)
    end

    it 'inherited from Dir are displayed as Dir', :mswin do
      class My < Dir; end

      require 'tmpdir'
      my = My.new(Dir.tmpdir)
      expect(my.ai(plain: true)).to eq("#{my.inspect}\n" + AmazingPrint::Formatters::GetChildItem.new(my.path).to_s)
    end

    it 'handles a class that defines its own #send method' do
      class My
        def send(arg1, arg2, arg3); end
      end

      my = My.new
      expect { my.methods.ai(plain: true) }.not_to raise_error
    end

    it 'handles a class defines its own #method method (ex. request.method)' do
      class My
        def method
          'POST'
        end
      end

      my = My.new
      expect { my.methods.ai(plain: true) }.not_to raise_error
    end

    describe 'should handle a class that defines its own #to_hash method' do
      it 'that takes arguments' do
        class My
          def to_hash(a, b); end
        end

        my = My.new
        expect { my.ai(plain: true) }.not_to raise_error
      end

      it 'that returns nil' do
        class My
          def to_hash
            nil
          end
        end

        my = My.new
        expect { my.ai(plain: true) }.not_to raise_error
      end

      it "that returns an object that doesn't support #keys" do
        class My
          def to_hash
            object = Object.new
            object.define_singleton_method('[]') { nil }

            object
          end
        end

        my = My.new
        expect { my.ai(plain: true) }.not_to raise_error
      end

      it "that returns an object that doesn't support subscripting" do
        class My
          def to_hash
            object = Object.new
            object.define_singleton_method(:keys) { [:foo] }

            object
          end
        end

        my = My.new
        expect { my.ai(plain: true) }.not_to raise_error
      end
    end
  end
end

# rubocop:enable Lint/ConstantDefinitionInBlock
