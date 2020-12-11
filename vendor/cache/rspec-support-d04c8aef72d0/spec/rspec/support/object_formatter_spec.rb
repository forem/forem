require 'rspec/support/object_formatter'
require 'rspec/matchers/fail_matchers'

module RSpec
  module Support
    RSpec.describe ObjectFormatter, ".format" do
      context 'with an array object containing other objects for which we have custom formatting' do
        let(:time)  { Time.utc(1969, 12, 31, 19, 01, 40, 101) }
        let(:formatted_time) { ObjectFormatter.format(time) }
        let(:input) { ["string", time, [3, time]] }

        it 'formats those objects within the array output, at any level of nesting' do
          formatted = ObjectFormatter.format(input)
          expect(formatted).to eq(%Q{["string", #{formatted_time}, [3, #{formatted_time}]]})
        end
      end

      context "with a hash object containing other objects for which we have custom formatting" do
        let(:time)  { Time.utc(1969, 12, 31, 19, 01, 40, 101) }
        let(:formatted_time) { ObjectFormatter.format(time) }
        let(:input) { { "key" => time, time => "value", "nested" => { "key" => time } } }

        it 'formats those objects within the hash output, at any level of nesting' do
          formatted = ObjectFormatter.format(input)

          if RUBY_VERSION == '1.8.7'
            # We can't count on the ordering of the hash on 1.8.7...
            expect(formatted).to include(%Q{"key"=>#{formatted_time}}, %Q{#{formatted_time}=>"value"}, %Q{"nested"=>{"key"=>#{formatted_time}}})
          else
            expect(formatted).to eq(%Q{{"key"=>#{formatted_time}, #{formatted_time}=>"value", "nested"=>{"key"=>#{formatted_time}}}})
          end
        end
      end

      unless RUBY_VERSION == '1.8.7' # We can't count on the ordering of the hash on 1.8.7...
        context 'with a hash object' do
          let(:input) { { :c => "ccc", :a => "aaa", "b" => 'bbb' } }
          let(:expected) { '{:a=>"aaa", "b"=>"bbb", :c=>"ccc"}' }

          it 'sorts keys to ensure objects are always displayed the same way' do
            formatted = ObjectFormatter.format(input)
            expect(formatted).to eq expected
          end
        end
      end

      context 'with Time objects' do
        let(:time) { Time.utc(1969, 12, 31, 19, 01, 40, 101) }
        let(:formatted_time) { ObjectFormatter.format(time) }

        it 'produces an extended output' do
          expected_output = "1969-12-31 19:01:40.000101"
          expect(formatted_time).to include(expected_output)
        end
      end

      context 'with DateTime objects' do
        def with_date_loaded
          in_sub_process_if_possible do
            require 'date'
            yield
          end
        end

        let(:date_time) { DateTime.new(2000, 1, 1, 1, 1, Rational(1, 10)) }
        let(:formatted_date_time) { ObjectFormatter.format(date_time) }

        it 'formats the DateTime using inspect' do
          with_date_loaded do
            expect(formatted_date_time).to eq(date_time.inspect)
          end
        end

        it 'does not require DateTime to be defined since you need to require `date` to make it available' do
          hide_const('DateTime')
          expect(ObjectFormatter.format('Test String')).to eq('"Test String"')
        end

        context 'when ActiveSupport is loaded' do
          it "uses a custom format to ensure the output is different when DateTimes differ" do
            stub_const("ActiveSupport", Module.new)

            with_date_loaded do
              expected_date_time = 'Sat, 01 Jan 2000 01:01:00.100000000 +0000'
              expect(formatted_date_time).to eq(expected_date_time)
            end
          end
        end
      end

      context 'with BigDecimal objects' do
        let(:float)   { 3.3 }
        let(:decimal) { BigDecimal("3.3") }

        let(:formatted_decimal) { ObjectFormatter.format(decimal) }

        if RUBY_VERSION >= '2.4'
          it "uses Ruby's BigDecimal formatting since it is improved in 2.4+" do
            in_sub_process_if_possible do
              require 'bigdecimal'
              expect(formatted_decimal).to eq('0.33e1')
            end
          end
        else
          it 'includes a conventional representation of the decimal' do
            in_sub_process_if_possible do
              require 'bigdecimal'
              # Suppress warning on JRuby 1.7:
              #   file:/Users/me/.rbenv/versions/jruby-1.7.26/lib/jruby.jar!/jruby/bigdecimal.rb:1
              #   warning: loading in progress, circular require considered harmful - bigdecimal.jar
              $stderr.reset!

              expect(formatted_decimal).to include('3.3 (#<BigDecimal')
            end
          end
        end

        it 'does not require BigDecimal to be defined since you need to require `bigdecimal` to make it available' do
          hide_const('BigDecimal')
          expect(ObjectFormatter.format('Test String')).to eq('"Test String"')
        end
      end

      context 'given a delegator' do
        def with_delegate_loaded
          in_sub_process_if_possible do
            require 'delegate'
            yield
          end
        end

        let(:object) { Object.new }
        let(:delegator) do
          SimpleDelegator.new(object)
        end

        it 'includes the delegator class in the description' do
          with_delegate_loaded do
            expect(ObjectFormatter.format(delegator)).to eq "#<SimpleDelegator(#{object.inspect})>"
          end
        end

        it 'includes the delegator class in the description even when protected' do
          with_delegate_loaded do
            protected_delegator = Class.new(SimpleDelegator) { protected :__getobj__ }
            expect(
              ObjectFormatter.format(protected_delegator.new(object))
            ).to eq "#<#{protected_delegator.inspect}(#{object.inspect})>"
          end
        end

        it 'does not require Delegator to be defined' do
          hide_const("Delegator")
          expect(ObjectFormatter.format(object)).to eq object.inspect
        end

        context 'for a specially-formatted object' do
          let(:decimal) { BigDecimal("3.3") }
          let(:formatted_decimal) { ObjectFormatter.format(decimal) }
          let(:object) { decimal }

          it 'formats the underlying object normally' do
            with_delegate_loaded do
              require 'bigdecimal'
              # Suppress warning on JRuby 1.7:
              #   file:/Users/me/.rbenv/versions/jruby-1.7.26/lib/jruby.jar!/jruby/bigdecimal.rb:1
              #   warning: loading in progress, circular require considered harmful - bigdecimal.jar
              $stderr.reset!

              expect(ObjectFormatter.format(delegator)).to eq "#<SimpleDelegator(#{formatted_decimal})>"
            end
          end
        end
      end

      context 'with objects that implement description' do
        RSpec::Matchers.define :matcher_with_description do
          match { true }
          description { "description" }
        end

        RSpec::Matchers.define :matcher_without_a_description do
          match { true }
          undef description
        end

        it "produces a description when a matcher object has a description" do
          expect(ObjectFormatter.format(matcher_with_description)).to eq("description")
        end

        it "does not produce a description unless the object is a matcher" do
          double = double('non-matcher double', :description => true)
          expect(ObjectFormatter.format(double)).to eq(double.inspect)
        end

        it "produces an inspected object when a matcher is missing a description" do
          expect(ObjectFormatter.format(matcher_without_a_description)).to eq(
            matcher_without_a_description.inspect)
        end
      end

      context 'with an object that does not respond to #class and #inspect such as BasicObject' do
        subject(:output) do
          ObjectFormatter.format(input)
        end

        let(:input) do
          if defined?(BasicObject)
            BasicObject.new
          else
            fake_basic_object_class.new
          end
        end

        let(:fake_basic_object_class) do
          Class.new do
            def self.to_s
              'BasicObject'
            end

            undef class, inspect, respond_to?
          end
        end

        if RUBY_VERSION == '1.9.2'
          it 'produces an #inspect-like output without object id' do
            expect(output).to eq('#<BasicObject:->')
          end
        else
          it "produces an output emulating MRI's #inspect-like output generated by C implementation" do
            expect(output).to match(/\A#<BasicObject:0x[0-9a-f]{14,16}>\z/)
          end
        end
      end

      context 'with a recursive array' do
        subject(:output) do
          ObjectFormatter.format(input)
        end

        let(:input) do
          array = [time]
          array << array
          array
        end

        let(:time) { Time.utc(1969, 12, 31, 19, 01, 40, 101) }

        let(:formatted_time) { ObjectFormatter.format(time) }

        it 'formats the recursive element as [...] and other elements with custom formatting' do
          expect(output).to eq("[#{formatted_time}, [...]]")
        end
      end

      context 'with a recursive-key hash' do
        subject(:output) do
          ObjectFormatter.format(input)
        end

        let(:input) do
          hash = {}
          hash[hash] = time
          hash
        end

        let(:time) { Time.utc(1969, 12, 31, 19, 01, 40, 101) }

        let(:formatted_time) { ObjectFormatter.format(time) }

        it 'formats the recursive element as {...} and other elements with custom formatting' do
          expect(output).to eq("{{...}=>#{formatted_time}}")
        end
      end

      context 'with a recursive-value hash' do
        subject(:output) do
          ObjectFormatter.format(input)
        end

        let(:input) do
          hash = {}
          hash[time] = hash
          hash
        end

        let(:time) { Time.utc(1969, 12, 31, 19, 01, 40, 101) }

        let(:formatted_time) { ObjectFormatter.format(time) }

        it 'formats the recursive element as {...} and other elements with custom formatting' do
          expect(output).to eq("{#{formatted_time}=>{...}}")
        end
      end

      context 'with a non-immediate recursive array' do
        subject(:output) do
          ObjectFormatter.format(input)
        end

        let(:input) do
          array = []
          array[0] = { :recursive_array => array }
          array
        end

        it 'formats the recursive element as [...]' do
          expect(output).to eq('[{:recursive_array=>[...]}]')
        end
      end

      context 'with a non-immediate recursive hash' do
        subject(:output) do
          ObjectFormatter.format(input)
        end

        let(:input) do
          hash = {}
          hash[:array] = [:next_is_recursive_hash, hash]
          hash
        end

        it 'formats the recursive element as {...}' do
          expect(output).to eq('{:array=>[:next_is_recursive_hash, {...}]}')
        end
      end

      context 'with an array including a same collection object multiple times' do
        subject(:output) do
          ObjectFormatter.format(input)
        end

        let(:input) do
          hash = { :key => 'value' }
          [hash, hash]
        end

        it 'does not omit them' do
          expect(output).to eq('[{:key=>"value"}, {:key=>"value"}]')
        end
      end

      context 'with truncation enabled' do
        it 'produces an output of limited length' do
          formatter = ObjectFormatter.new(10)
          expect(formatter.format('Test String Of A Longer Length')).to eq('"Test ...ngth"')
        end

        it 'does not truncate shorter strings' do
          formatter = ObjectFormatter.new(10)
          expect(formatter.format('Testing')).to eq('"Testing"')
        end

        context 'with ANSI escape codes that fall on the truncate split' do
          it 'removes that escape code so terminals do not get corrupted print a partial escape code' do
            formatter = ObjectFormatter.new(38)
            object = Class.new do
              def inspect
                "#<\e[33mClass\e[0m \e[36mname: \e[0m\"foobars\" \e[36mcount: \e[0m42>"
              end
            end.new
            expect(formatter.format(object)).to eq("#<\e[33mClass\e[0m ...\e[36mcount: \e[0m42>")
          end
        end
      end

      context 'with truncation disabled' do
        it 'does not limit the output length' do
          formatter = ObjectFormatter.new(nil)
          expect(formatter.format('Test String Of A Longer Length')).to eq('"Test String Of A Longer Length"')
        end
      end
    end
  end
end
