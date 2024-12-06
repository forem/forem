# frozen_string_literal: true

# rubocop:disable Lint/ConstantDefinitionInBlock

require 'spec_helper'

RSpec.describe 'Single method' do
  after do
    Object.instance_eval { remove_const :Hello } if defined?(Hello)
  end

  it 'plain: should handle a method with no arguments' do
    method = ''.method(:upcase)
    if RUBY_VERSION >= '2.4.0'
      expect(method.ai(plain: true)).to eq('String#upcase(*arg1)')
    else
      expect(method.ai(plain: true)).to eq('String#upcase()')
    end
  end

  it 'color: should handle a method with no arguments' do
    method = ''.method(:upcase)
    if RUBY_VERSION >= '2.4.0'
      expect(method.ai).to eq("\e[1;33mString\e[0m#\e[0;35mupcase\e[0m\e[0;37m(*arg1)\e[0m")
    else
      expect(method.ai).to eq("\e[1;33mString\e[0m#\e[0;35mupcase\e[0m\e[0;37m()\e[0m")
    end
  end

  it 'plain: should handle a method with one argument' do
    method = ''.method(:include?)
    expect(method.ai(plain: true)).to eq('String#include?(arg1)')
  end

  it 'color: should handle a method with one argument' do
    method = ''.method(:include?)
    expect(method.ai).to eq("\e[1;33mString\e[0m#\e[0;35minclude?\e[0m\e[0;37m(arg1)\e[0m")
  end

  it 'plain: should handle a method with one required keyword argument' do
    class A
      def one(foo:); end
    end
    method = A.new.method(:one)
    expect(method.ai(plain: true)).to eq('A#one(foo:)')
  end

  it 'color: should handle a method with one required keyword argument' do
    class A
      def one(foo:); end
    end
    method = A.new.method(:one)
    expect(method.ai).to eq("\e[1;33mA\e[0m#\e[0;35mone\e[0m\e[0;37m(foo:)\e[0m")
  end

  it 'plain: should handle a method with one required and one optional keyword arguments' do
    class A
      def one(foo:, bar: 'baz'); end
    end
    method = A.new.method(:one)
    expect(method.ai(plain: true)).to eq('A#one(foo:, *bar:)')
  end

  it 'color: should handle a method with one required and one optional keyword arguments' do
    class A
      def one(foo:, bar: 'baz'); end
    end
    method = A.new.method(:one)
    expect(method.ai).to eq("\e[1;33mA\e[0m#\e[0;35mone\e[0m\e[0;37m(foo:, *bar:)\e[0m")
  end

  it 'plain: should handle a method with two arguments' do
    method = ''.method(:tr)
    expect(method.ai(plain: true)).to eq('String#tr(arg1, arg2)')
  end

  it 'color: should handle a method with two arguments' do
    method = ''.method(:tr)
    expect(method.ai).to eq("\e[1;33mString\e[0m#\e[0;35mtr\e[0m\e[0;37m(arg1, arg2)\e[0m")
  end

  it 'plain: should handle a method with multiple arguments' do
    method = ''.method(:split)
    expect(method.ai(plain: true)).to eq('String#split(*arg1)')
  end

  it 'color: should handle a method with multiple arguments' do
    method = ''.method(:split)
    expect(method.ai).to eq("\e[1;33mString\e[0m#\e[0;35msplit\e[0m\e[0;37m(*arg1)\e[0m")
  end

  it 'plain: should handle a method defined in mixin' do
    method = ''.method(:is_a?)
    expect(method.ai(plain: true)).to eq('String (Kernel)#is_a?(arg1)')
  end

  it 'color: should handle a method defined in mixin' do
    method = ''.method(:is_a?)
    expect(method.ai).to eq("\e[1;33mString (Kernel)\e[0m#\e[0;35mis_a?\e[0m\e[0;37m(arg1)\e[0m")
  end

  it 'plain: should handle an unbound method' do
    class Hello
      def world; end
    end
    method = Hello.instance_method(:world)
    expect(method.ai(plain: true)).to eq('Hello (unbound)#world()')
  end

  it 'color: should handle an unbound method' do
    class Hello
      def world(a, b); end
    end
    method = Hello.instance_method(:world)
    if RUBY_VERSION < '1.9.2'
      expect(method.ai).to eq("\e[1;33mHello (unbound)\e[0m#\e[0;35mworld\e[0m\e[0;37m(arg1, arg2)\e[0m")
    else
      expect(method.ai).to eq("\e[1;33mHello (unbound)\e[0m#\e[0;35mworld\e[0m\e[0;37m(a, b)\e[0m")
    end
  end
end

RSpec.describe 'Object methods' do
  after do
    Object.instance_eval { remove_const :Hello } if defined?(Hello)
  end

  describe 'object.methods' do
    it 'index: should handle object.methods' do
      out = nil.methods.ai(plain: true).split("\n").grep(/is_a\?/).first
      expect(out).to match(/^\s+\[\s*\d+\]\s+is_a\?\(arg1\)\s+NilClass \(Kernel\)$/)
    end

    it 'no index: should handle object.methods' do
      out = nil.methods.ai(plain: true, index: false).split("\n").grep(/is_a\?/).first
      expect(out).to match(/^\s+is_a\?\(arg1\)\s+NilClass \(Kernel\)$/)
    end
  end

  describe 'object.public_methods' do
    it 'index: should handle object.public_methods' do
      out = nil.public_methods.ai(plain: true).split("\n").grep(/is_a\?/).first
      expect(out).to match(/^\s+\[\s*\d+\]\s+is_a\?\(arg1\)\s+NilClass \(Kernel\)$/)
    end

    it 'no index: should handle object.public_methods' do
      out = nil.public_methods.ai(plain: true, index: false).split("\n").grep(/is_a\?/).first
      expect(out).to match(/^\s+is_a\?\(arg1\)\s+NilClass \(Kernel\)$/)
    end
  end

  describe 'object.private_methods' do
    it 'index: should handle object.private_methods' do
      out = nil.private_methods.ai(plain: true).split("\n").grep(/sleep/).first
      expect(out).to match(/^\s+\[\s*\d+\]\s+sleep\(\*arg1\)\s+NilClass \(Kernel\)$/)
    end

    it 'no index: should handle object.private_methods' do
      out = nil.private_methods.ai(plain: true, index: false).split("\n").grep(/sleep/).first
      expect(out).to match(/^\s+sleep\(\*arg1\)\s+NilClass \(Kernel\)$/)
    end
  end

  describe 'object.protected_methods' do
    it 'index: should handle object.protected_methods' do
      class Hello
        protected

        def m1; end

        def m2; end
      end
      expect(Hello.new.protected_methods.ai(plain: true)).to eq("[\n    [0] m1() Hello\n    [1] m2() Hello\n]")
    end

    it 'no index: should handle object.protected_methods' do
      class Hello
        protected

        def m3(a, b); end
      end
      if RUBY_VERSION < '1.9.2'
        expect(Hello.new.protected_methods.ai(plain: true, index: false)).to eq("[\n     m3(arg1, arg2) Hello\n]")
      else
        expect(Hello.new.protected_methods.ai(plain: true, index: false)).to eq("[\n     m3(a, b) Hello\n]")
      end
    end
  end

  describe 'object.private_methods' do
    it 'index: should handle object.private_methods' do
      class Hello
        private

        def m1; end

        def m2; end
      end

      out = Hello.new.private_methods.ai(plain: true).split("\n").grep(/m\d/)
      expect(out.first).to match(/^\s+\[\s*\d+\]\s+m1\(\)\s+Hello$/)
      expect(out.last).to  match(/^\s+\[\s*\d+\]\s+m2\(\)\s+Hello$/)
    end

    it 'no index: should handle object.private_methods' do
      class Hello
        private

        def m3(a, b); end
      end
      out = Hello.new.private_methods.ai(plain: true).split("\n").grep(/m\d/)
      if RUBY_VERSION < '1.9.2'
        expect(out.first).to match(/^\s+\[\s*\d+\]\s+m3\(arg1, arg2\)\s+Hello$/)
      else
        expect(out.first).to match(/^\s+\[\s*\d+\]\s+m3\(a, b\)\s+Hello$/)
      end
    end
  end

  describe 'object.singleton_methods' do
    it 'index: should handle object.singleton_methods' do
      class Hello
        class << self
          def m1; end

          def m2; end
        end
      end
      out = Hello.singleton_methods.ai(plain: true).split("\n").grep(/m\d/)
      expect(out.first).to match(/^\s+\[\s*\d+\]\s+m1\(\)\s+Hello$/)
      expect(out.last).to  match(/^\s+\[\s*\d+\]\s+m2\(\)\s+Hello$/)
    end

    it 'no index: should handle object.singleton_methods' do
      class Hello
        def self.m3(a, b); end
      end
      out = Hello.singleton_methods.ai(plain: true, index: false).split("\n").grep(/m\d/)
      if RUBY_VERSION < '1.9.2'
        expect(out.first).to match(/^\s+m3\(arg1, arg2\)\s+Hello$/)
      else
        expect(out.first).to match(/^\s+m3\(a, b\)\s+Hello$/)
      end
    end
  end
end

RSpec.describe 'Class methods' do
  after do
    Object.instance_eval { remove_const :Hello } if defined?(Hello)
  end

  describe 'class.instance_methods' do
    it 'index: should handle unbound class.instance_methods' do
      class Hello
        def m1; end

        def m2; end
      end
      out = Hello.instance_methods.ai(plain: true).split("\n").grep(/m\d/)
      expect(out.first).to match(/^\s+\[\s*\d+\]\s+m1\(\)\s+Hello\s\(unbound\)$/)
      expect(out.last).to  match(/^\s+\[\s*\d+\]\s+m2\(\)\s+Hello\s\(unbound\)$/)
    end

    it 'no index: should handle unbound class.instance_methods' do
      class Hello
        def m3(a, b); end
      end
      out = Hello.instance_methods.ai(plain: true, index: false).split("\n").grep(/m\d/)
      if RUBY_VERSION < '1.9.2'
        expect(out.first).to match(/^\s+m3\(arg1, arg2\)\s+Hello\s\(unbound\)$/)
      else
        expect(out.first).to match(/^\s+m3\(a, b\)\s+Hello\s\(unbound\)$/)
      end
    end
  end

  describe 'class.public_instance_methods' do
    it 'index: should handle class.public_instance_methods' do
      class Hello
        def m1; end

        def m2; end
      end
      out = Hello.public_instance_methods.ai(plain: true).split("\n").grep(/m\d/)
      expect(out.first).to match(/^\s+\[\s*\d+\]\s+m1\(\)\s+Hello\s\(unbound\)$/)
      expect(out.last).to  match(/^\s+\[\s*\d+\]\s+m2\(\)\s+Hello\s\(unbound\)$/)
    end

    it 'no index: should handle class.public_instance_methods' do
      class Hello
        def m3(a, b); end
      end
      out = Hello.public_instance_methods.ai(plain: true, index: false).split("\n").grep(/m\d/)
      if RUBY_VERSION < '1.9.2'
        expect(out.first).to match(/^\s+m3\(arg1, arg2\)\s+Hello\s\(unbound\)$/)
      else
        expect(out.first).to match(/^\s+m3\(a, b\)\s+Hello\s\(unbound\)$/)
      end
    end
  end

  describe 'class.protected_instance_methods' do
    it 'index: should handle class.protected_instance_methods' do
      class Hello
        protected

        def m1; end

        def m2; end
      end
      out = Hello.protected_instance_methods.ai(plain: true).split("\n").grep(/m\d/)
      expect(out.first).to match(/^\s+\[\s*\d+\]\s+m1\(\)\s+Hello\s\(unbound\)$/)
      expect(out.last).to  match(/^\s+\[\s*\d+\]\s+m2\(\)\s+Hello\s\(unbound\)$/)
    end

    it 'no index: should handle class.protected_instance_methods' do
      class Hello
        protected

        def m3(a, b); end
      end
      out = Hello.protected_instance_methods.ai(plain: true, index: false).split("\n").grep(/m\d/)
      if RUBY_VERSION < '1.9.2'
        expect(out.first).to match(/^\s+m3\(arg1, arg2\)\s+Hello\s\(unbound\)$/)
      else
        expect(out.first).to match(/^\s+m3\(a, b\)\s+Hello\s\(unbound\)$/)
      end
    end
  end

  describe 'class.private_instance_methods' do
    it 'index: should handle class.private_instance_methods' do
      class Hello
        private

        def m1; end

        def m2; end
      end
      out = Hello.private_instance_methods.ai(plain: true).split("\n").grep(/m\d/)
      expect(out.first).to match(/^\s+\[\s*\d+\]\s+m1\(\)\s+Hello\s\(unbound\)$/)
      expect(out.last).to  match(/^\s+\[\s*\d+\]\s+m2\(\)\s+Hello\s\(unbound\)$/)
    end

    it 'no index: should handle class.private_instance_methods' do
      class Hello
        private

        def m3(a, b); end
      end
      out = Hello.private_instance_methods.ai(plain: true, index: false).split("\n").grep(/m\d/)
      if RUBY_VERSION < '1.9.2'
        expect(out.first).to match(/^\s+m3\(arg1, arg2\)\s+Hello\s\(unbound\)$/)
      else
        expect(out.first).to match(/^\s+m3\(a, b\)\s+Hello\s\(unbound\)$/)
      end
    end
  end
end

if RUBY_VERSION >= '1.9.2'
  RSpec.describe 'Ruby 1.9.2+ Method#parameters' do
    before do
      stub_dotfile!
    end

    after do
      Object.instance_eval { remove_const :Hello } if defined?(Hello)
    end

    it '()' do
      class Hello
        def m1; end
      end
      out = Hello.new.methods.ai(plain: true).split("\n").grep(/m1/)
      expect(out.first).to match(/^\s+\[\s*\d+\]\s+m1\(\)\s+Hello$/)
    end

    it ':req' do
      class Hello
        def m1(a, b, c); end
      end
      out = Hello.new.methods.ai(plain: true).split("\n").grep(/m1/)
      expect(out.first).to match(/^\s+\[\s*\d+\]\s+m1\(a, b, c\)\s+Hello$/)
    end

    it ':opt' do
      class Hello
        # m1(a, *b, *c)
        def m1(a, b = 1, c = 2); end
      end
      out = Hello.new.methods.ai(plain: true).split("\n").grep(/m1/)
      expect(out.first).to match(/^\s+\[\s*\d+\]\s+m1\(a, \*b, \*c\)\s+Hello$/)
    end

    it ':rest' do
      class Hello
        # m1(*a)
        def m1(*a); end
      end
      out = Hello.new.methods.ai(plain: true).split("\n").grep(/m1/)
      expect(out.first).to match(/^\s+\[\s*\d+\]\s+m1\(\*a\)\s+Hello$/)
    end

    it ':block' do
      class Hello
        # m1(a, *b, &blk)
        def m1(a, b = nil, &blk); end
      end
      out = Hello.new.methods.ai(plain: true).split("\n").grep(/m1/)
      expect(out.first).to match(/^\s+\[\s*\d+\]\s+m1\(a, \*b, &blk\)\s+Hello$/)
    end
  end
end

RSpec.describe 'Methods arrays' do
  after do
    Object.instance_eval { remove_const :Hello } if defined?(Hello)
    Object.instance_eval { remove_const :World } if defined?(World)
  end

  it 'obj1.methods - obj2.methods should be awesome printed' do
    stub_dotfile!
    class Hello
      def self.m1; end
    end
    out = (Hello.methods - Class.methods).ai(plain: true)
    expect(out).to eq("[\n    [0] m1() Hello\n]")
  end

  it 'obj1.methods & obj2.methods should be awesome printed' do
    stub_dotfile!
    class Hello
      def self.m1; end

      def self.m2; end
    end

    class World
      def self.m1; end
    end
    out = (Hello.methods & (World.methods - Class.methods)).ai(plain: true)
    expect(out).to eq("[\n    [0] m1() Hello\n]")
  end

  it 'obj1.methods.grep(pattern) should be awesome printed' do
    stub_dotfile!
    class Hello
      def self.m1; end

      def self.m2; end

      def self.m3; end
    end
    out = Hello.methods.grep(/^m1$/).ai(plain: true)
    expect(out).to eq("[\n    [0] m1() Hello\n]")
    out = Hello.methods.grep(/^m\d$/).ai(plain: true)
    expect(out).to eq("[\n    [0] m1() Hello\n    [1] m2() Hello\n    [2] m3() Hello\n]")
  end

  it 'obj1.methods.grep(pattern, &block) should pass the matching string within the block' do
    class Hello
      def self.m_one; end

      def self.m_two; end
    end

    out = Hello.methods.sort.grep(/^m_(.+)$/) { Regexp.last_match(1).to_sym }
    expect(out).to eq(%i[one two])
  end

  it 'obj1.methods.grep(pattern, &block) should be awesome printed' do
    stub_dotfile!
    class Hello
      def self.m0; end

      def self.none; end

      def self.m1; end

      def self.one; end
    end

    out = Hello.methods.grep(/^m(\d)$/) { %w[none one][Regexp.last_match(1).to_i] }.ai(plain: true)
    expect(out).to eq("[\n    [0] none() Hello\n    [1]  one() Hello\n]")
  end

  # See https://github.com/awesome-print/awesome_print/issues/30 for details.
  it 'grepping methods and converting them to_sym should work as expected' do
    class Hello
      private

      def him; end

      def his
        private_methods.grep(/^h..$/, &:to_sym)
      end

      def her
        private_methods.grep(/^.e.$/, &:to_sym)
      end
    end

    hello = Hello.new
    expect((hello.send(:his) - hello.send(:her)).sort_by(&:to_s)).to eq(%i[him his])
  end

  it 'appending garbage to methods array should not raise error' do
    arr = 42.methods << [:wtf]
    expect { arr.ai(plain: true) }.not_to raise_error
    if RUBY_VERSION < '1.9.2'
      expect(arr.ai(plain: true)).to match(/\s+wtf\(\?\)\s+\?/)      # [ :wtf ].to_s => "wtf"
    else
      expect(arr.ai(plain: true)).to match(/\s+\[:wtf\]\(\?\)\s+\?/) # [ :wtf ].to_s => [:wtf]
    end
  end
end

# rubocop:enable Lint/ConstantDefinitionInBlock
