# frozen_string_literal: true

# rubocop:disable Lint/ConstantDefinitionInBlock

require 'spec_helper'

RSpec.describe 'Objects' do
  after do
    Object.instance_eval { remove_const :Hello } if defined?(Hello)
  end

  describe 'Formatting an object' do
    it 'attributes' do
      class Hello
        attr_reader   :abra
        attr_writer   :ca
        attr_accessor :dabra

        def initialize
          @abra = 1
          @ca = 2
          @dabra = 3
        end
      end

      hello = Hello.new
      out = hello.ai(plain: true, raw: true)
      str = <<~EOS.strip
        #<Hello:placeholder_id
            attr_accessor :dabra = 3,
            attr_reader :abra = 1,
            attr_writer :ca = 2
        >
      EOS
      expect(out).to be_similar_to(str)
      expect(hello.ai(plain: true, raw: false)).to eq(hello.inspect)
    end

    it 'instance variables' do
      class Hello
        def initialize
          @abra = 1
          @ca = 2
          @dabra = 3
        end
      end

      hello = Hello.new
      out = hello.ai(plain: true, raw: true)
      str = <<~EOS.strip
        #<Hello:placeholder_id
            @abra = 1,
            @ca = 2,
            @dabra = 3
        >
      EOS
      expect(out).to be_similar_to(str)
      expect(hello.ai(plain: true, raw: false)).to eq(hello.inspect)
    end

    it 'attributes and instance variables' do
      class Hello
        attr_reader   :abra
        attr_writer   :ca
        attr_accessor :dabra

        def initialize
          @abra = 1
          @ca = 2
          @dabra = 3
          @scooby = 3
          @dooby = 2
          @doo = 1
        end
      end

      hello = Hello.new
      out = hello.ai(plain: true, raw: true)
      str = <<~EOS.strip
        #<Hello:placeholder_id
            @doo = 1,
            @dooby = 2,
            @scooby = 3,
            attr_accessor :dabra = 3,
            attr_reader :abra = 1,
            attr_writer :ca = 2
        >
      EOS
      expect(out).to be_similar_to(str)
      expect(hello.ai(plain: true, raw: false)).to eq(hello.inspect)
    end

    it 'without the plain options print the colorized values' do
      class Hello
        attr_reader   :abra
        attr_writer   :ca

        def initialize
          @abra = 1
          @ca = 2
          @dabra = 3
        end
      end

      hello = Hello.new
      out = hello.ai(raw: true)
      str = <<~EOS.strip
        #<Hello:placeholder_id
            \e[0;36m@dabra\e[0m\e[0;37m = \e[0m\e[1;34m3\e[0m,
            \e[1;36mattr_reader\e[0m \e[0;35m:abra\e[0m\e[0;37m = \e[0m\e[1;34m1\e[0m,
            \e[1;36mattr_writer\e[0m \e[0;35m:ca\e[0m\e[0;37m = \e[0m\e[1;34m2\e[0m
        >
      EOS
      expect(out).to be_similar_to(str)
      expect(hello.ai(plain: true, raw: false)).to eq(hello.inspect)
    end

    it 'with multine as false show inline values' do
      class Hello
        attr_reader   :abra
        attr_writer   :ca

        def initialize
          @abra = 1
          @ca = 2
          @dabra = 3
        end
      end

      hello = Hello.new
      out = hello.ai(multiline: false, plain: true, raw: true)
      str = <<~EOS.strip
        #<Hello:placeholder_id @dabra = 3, attr_reader :abra = 1, attr_writer :ca = 2>
      EOS
      expect(out).to be_similar_to(str)
      expect(hello.ai(plain: true, raw: false)).to eq(hello.inspect)
    end

    it 'without the sort_vars option does not sort instance variables' do
      class Hello
        attr_reader   :abra
        attr_writer   :ca
        attr_accessor :dabra

        def initialize
          @abra = 1
          @ca = 2
          @dabra = 3
          @scooby = 3
          @dooby = 2
          @doo = 1
        end

        def instance_variables
          %i[@scooby @dooby @doo @abra @ca @dabra]
        end
      end

      hello = Hello.new
      out = hello.ai(plain: true, raw: true, sort_vars: false)
      str = <<~EOS.strip
        #<Hello:placeholder_id
            @scooby = 3,
            @dooby = 2,
            @doo = 1,
            attr_reader :abra = 1,
            attr_writer :ca = 2,
            attr_accessor :dabra = 3
        >
      EOS
      expect(out).to be_similar_to(str)
      expect(hello.ai(plain: true, raw: false)).to eq(hello.inspect)
    end

    it 'object_id' do
      class Hello
        def initialize
          @abra = 1
          @ca = 2
          @dabra = 3
        end
      end

      hello = Hello.new
      out = hello.ai(plain: true, raw: true, object_id: false)
      str = <<~EOS.strip
        #<Hello
            @abra = 1,
            @ca = 2,
            @dabra = 3
        >
      EOS
      expect(out).to be_similar_to(str)
      expect(hello.ai(plain: true, raw: false)).to eq(hello.inspect)
    end

    it 'class_name' do
      class Hello
        def initialize
          @abra = 1
          @ca = 2
          @dabra = 3
        end

        def to_s
          'CustomizedHello'
        end
      end

      hello = Hello.new
      out = hello.ai(plain: true, raw: true, class_name: :to_s)
      str = <<~EOS.strip
        #<CustomizedHello:placeholder_id
            @abra = 1,
            @ca = 2,
            @dabra = 3
        >
      EOS
      expect(out).to be_similar_to(str)
      expect(hello.ai(plain: true, raw: false)).to eq(hello.inspect)
    end
  end
end

# rubocop:enable Lint/ConstantDefinitionInBlock
