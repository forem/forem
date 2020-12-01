require 'rspec/support'
require 'rspec/support/method_signature_verifier'

module RSpec
  module Support
    RSpec.describe 'verifying methods' do
      let(:signature) { MethodSignature.new(test_method) }

      def valid_non_kw_args?(arity)
        described_class.new(signature, [nil] * arity).valid?
      end

      def valid?(*args)
        described_class.new(signature, args).valid?
      end

      def error_description
        described_class.new(signature).error_message[/Expected (.*),/, 1]
      end

      def error_for(*args)
        described_class.new(signature, args).error_message
      end

      def signature_description
        signature.description
      end

      def validate_expectation(*args)
        obj = MethodSignatureExpectation.new

        obj.min_count = Integer === args.first ? args.shift : nil
        obj.max_count = Integer === args.first ? args.shift : nil

        obj.expect_unlimited_arguments = !args.delete(:unlimited_args).nil?
        obj.expect_arbitrary_keywords  = !args.delete(:arbitrary_kw_args).nil?

        obj.keywords = args

        described_class.new(signature).with_expectation(obj).valid?
      end

      shared_context 'a method verifier' do
        describe 'with a method with arguments' do
          def arity_two(x, y); end

          let(:test_method) { method(:arity_two) }

          it 'covers only the exact arity' do
            expect(valid_non_kw_args?(1)).to eq(false)
            expect(valid_non_kw_args?(2)).to eq(true)
            expect(valid_non_kw_args?(3)).to eq(false)
          end

          it "allows matchers to be passed as arguments" do
            expect(valid?(anything, anything)).to eq(true)
          end

          it 'does not treat a last-arg hash as kw args' do
            expect(valid?(1, {})).to eq(true)
          end

          it 'describes the arity precisely' do
            expect(error_description).to eq("2")
          end

          it 'mentions only the arity in the description' do
            expect(signature_description).to eq("arity of 2")
          end

          it 'indicates it has no optional kw args' do
            expect(signature.optional_kw_args).to eq([])
          end

          it 'indicates it has no required kw args' do
            expect(signature.required_kw_args).to eq([])
          end

          describe 'with an expectation object' do
            it 'matches the exact arity' do
              expect(validate_expectation 1).to eq(false)
              expect(validate_expectation 2).to eq(true)
              expect(validate_expectation 3).to eq(false)
            end

            it 'matches a range including the min and max counts' do
              expect(validate_expectation 1, 2).to eq(false)
              expect(validate_expectation 2, 2).to eq(true)
              expect(validate_expectation 2, 3).to eq(false)
            end

            it 'does not match unlimited arguments' do
              expect(validate_expectation :unlimited_args).to eq(false)
            end

            if RubyFeatures.kw_args_supported?
              it 'does not match keywords' do
                expect(validate_expectation :optional_keyword).to eq(false)
                expect(validate_expectation 2, :optional_keyword).to eq(false)
              end

              it 'does not match arbitrary keywords' do
                expect(validate_expectation :arbitrary_kw_args).to eq(false)
              end
            else
              it 'ignores keyword expectations' do
                expect(validate_expectation :optional_keyword).to eq(false)
                expect(validate_expectation 2, :optional_keyword).to eq(true)
              end

              it 'ignores arbitrary keyword expectations' do
                expect(validate_expectation :arbitrary_kw_args).to eq(false)
                expect(validate_expectation 2, :arbitrary_kw_args).to eq(true)
              end
            end
          end
        end

        describe 'a method with splat arguments' do
          def arity_splat(_, *); end

          let(:test_method) { method(:arity_splat) }

          it 'covers a range from the lower bound upwards' do
            expect(valid_non_kw_args?(0)).to eq(false)
            expect(valid_non_kw_args?(1)).to eq(true)
            expect(valid_non_kw_args?(2)).to eq(true)
            expect(valid_non_kw_args?(3)).to eq(true)
          end

          it 'describes the arity with no upper bound' do
            expect(error_description).to eq("1 or more")
          end

          it 'mentions only the arity in the description' do
            expect(signature_description).to eq("arity of 1 or more")
          end

          describe 'with an expectation object' do
            it 'matches a value from the lower bound upwards' do
              expect(validate_expectation 0).to eq(false)
              expect(validate_expectation 1).to eq(true)
              expect(validate_expectation 2).to eq(true)
              expect(validate_expectation 3).to eq(true)
            end

            it 'matches a range from the lower bound upwards' do
              expect(validate_expectation 0, 1).to eq(false)
              expect(validate_expectation 1, 1).to eq(true)
              expect(validate_expectation 1, 2).to eq(true)
              expect(validate_expectation 2, 3).to eq(true)
              expect(validate_expectation 1, 2 ** 31).to eq(true)
            end

            if RubyFeatures.optional_and_splat_args_supported?
              it 'matches unlimited arguments with the minimum arity' do
                expect(validate_expectation :unlimited_args).to eq(false)

                expect(validate_expectation 1, :unlimited_args).to eq(true)
              end
            else
              it 'ignores unlimited arguments expectations' do
                expect(validate_expectation :unlimited_args).to eq(false)

                expect(validate_expectation 1, :unlimited_args).to eq(true)
              end
            end

            if RubyFeatures.kw_args_supported?
              it 'does not match keywords' do
                expect(validate_expectation :optional_keyword).to eq(false)
                expect(validate_expectation 2, :optional_keyword).to eq(false)
              end

              it 'does not match arbitrary keywords' do
                expect(validate_expectation :arbitrary_kw_args).to eq(false)
                expect(validate_expectation 2, :arbitrary_kw_args).to eq(false)
              end
            else
              it 'ignores keyword expectations' do
                expect(validate_expectation :optional_keyword).to eq(false)
                expect(validate_expectation 2, :optional_keyword).to eq(true)
              end

              it 'ignores arbitrary keyword expectations' do
                expect(validate_expectation :arbitrary_kw_args).to eq(false)
                expect(validate_expectation 2, :arbitrary_kw_args).to eq(true)
              end
            end
          end
        end

        describe 'a method with optional arguments' do
          def arity_optional(x, y, z = 1); end

          let(:test_method) { method(:arity_optional) }

          it 'covers a range from min to max possible arguments' do
            expect(valid_non_kw_args?(1)).to eq(false)
            expect(valid_non_kw_args?(2)).to eq(true)
            expect(valid_non_kw_args?(3)).to eq(true)

            if RubyFeatures.optional_and_splat_args_supported?
              expect(valid_non_kw_args?(4)).to eq(false)
            else
              expect(valid_non_kw_args?(4)).to eq(true)
            end
          end

          if RubyFeatures.optional_and_splat_args_supported?
            it 'describes the arity as a range' do
              expect(error_description).to eq("2 to 3")
            end
          else
            it 'describes the arity with no upper bound' do
              expect(error_description).to eq("2 or more")
            end
          end

          describe 'with an expectation object' do
            it 'matches a value from min to max possible arguments' do
              expect(validate_expectation 1).to eq(false)
              expect(validate_expectation 2).to eq(true)
              expect(validate_expectation 3).to eq(true)

              if RubyFeatures.optional_and_splat_args_supported?
                expect(validate_expectation 4).to eq(false)
              else
                expect(validate_expectation 4).to eq(true)
              end
            end

            it 'matches a range from the lower bound upwards' do
              expect(validate_expectation 1, 2).to eq(false)
              expect(validate_expectation 2, 2).to eq(true)
              expect(validate_expectation 2, 3).to eq(true)

              if RubyFeatures.optional_and_splat_args_supported?
                expect(validate_expectation 2, 4).to eq(false)
              else
                expect(validate_expectation 2, 4).to eq(true)
              end
            end

            it 'does not match unlimited arguments' do
              expect(validate_expectation :unlimited_args).to eq(false)
            end

            if RubyFeatures.kw_args_supported?
              it 'does not match keywords' do
                expect(validate_expectation :optional_keyword).to eq(false)
                expect(validate_expectation 2, :optional_keyword).to eq(false)
              end

              it 'does not match arbitrary keywords' do
                expect(validate_expectation :arbitrary_kw_args).to eq(false)
              end
            else
              it 'ignores keyword expectations' do
                expect(validate_expectation :optional_keyword).to eq(false)

                expect(validate_expectation 2, :optional_keyword).to eq(true)
              end

              it 'ignores arbitrary keyword expectations' do
                expect(validate_expectation :arbitrary_kw_args).to eq(false)

                expect(validate_expectation 2, :arbitrary_kw_args).to eq(true)
              end
            end
          end
        end

        if RubyFeatures.kw_args_supported?
          describe 'a method with optional keyword arguments' do
            eval <<-RUBY
              def arity_kw(x, y:1, z:2); end
            RUBY

            let(:test_method) { method(:arity_kw) }

            it 'does not require any of the arguments' do
              expect(valid?(nil)).to eq(true)
              expect(valid?(nil, nil)).to eq(false)
            end

            it 'does not allow an invalid keyword arguments' do
              expect(valid?(nil, :a => 1)).to eq(false)
            end

            it 'mentions the invalid keyword args in the error', :pending => RSpec::Support::Ruby.jruby? && !RSpec::Support::Ruby.jruby_9000? do
              expect(error_for(nil, :a => 0, :b => 1)).to \
                eq("Invalid keyword arguments provided: a, b")
            end

            it 'describes invalid arity precisely' do
              expect(error_for()).to \
                eq("Wrong number of arguments. Expected 1, got 0.")
            end

            it 'does not blow up when given a BasicObject as the last arg' do
              expect(valid?(BasicObject.new)).to eq(true)
            end

            it 'does not mutate the provided args array' do
              args = [nil, { :y => 1 }]
              described_class.new(signature, args).valid?
              expect(args).to eq([nil, { :y => 1 }])
            end

            it 'mentions the arity and optional kw args in the description', :pending => RSpec::Support::Ruby.jruby? && !RSpec::Support::Ruby.jruby_9000? do
              expect(signature_description).to eq("arity of 1 and optional keyword args (:y, :z)")
            end

            it "indicates the optional keyword args" do
              expect(signature.optional_kw_args).to contain_exactly(:y, :z)
            end

            it "indicates it has no required keyword args" do
              expect(signature.required_kw_args).to eq([])
            end

            describe 'with an expectation object' do
              it 'matches the exact arity' do
                expect(validate_expectation 0).to eq(false)
                expect(validate_expectation 1).to eq(true)
                expect(validate_expectation 2).to eq(false)
              end

              it 'matches the exact range' do
                expect(validate_expectation 0, 1).to eq(false)
                expect(validate_expectation 1, 1).to eq(true)
                expect(validate_expectation 1, 2).to eq(false)
              end

              it 'does not match unlimited arguments' do
                expect(validate_expectation :unlimited_args).to eq(false)
              end

              it 'matches optional keywords with the correct arity' do
                expect(validate_expectation :y).to eq(false)
                expect(validate_expectation :z).to eq(false)
                expect(validate_expectation :y, :z).to eq(false)

                expect(validate_expectation 1, :y).to eq(true)
                expect(validate_expectation 1, :z).to eq(true)
                expect(validate_expectation 1, :y, :z).to eq(true)

                expect(validate_expectation 2, :y).to eq(false)
                expect(validate_expectation 2, :z).to eq(false)
                expect(validate_expectation 2, :y, :z).to eq(false)
              end

              it 'does not match invalid keywords' do
                expect(validate_expectation :w).to eq(false)
                expect(validate_expectation :w, :z).to eq(false)

                expect(validate_expectation 1, :w).to eq(false)
                expect(validate_expectation 1, :w, :z).to eq(false)
              end

              it 'does not match arbitrary keywords' do
                expect(validate_expectation :arbitrary_kw_args).to eq(false)
              end
            end
          end
        end

        if RubyFeatures.kw_args_supported?
          describe 'a method with optional argument and keyword arguments' do
            eval <<-RUBY
              def arity_kw(x, y = {}, z:2); end
            RUBY

            let(:test_method) { method(:arity_kw) }

            it 'does not require any of the arguments' do
              expect(valid?(nil)).to eq(true)
              expect(valid?(nil, nil)).to eq(true)
            end

            it 'does not allow an invalid keyword arguments' do
              expect(valid?(nil, nil, :a => 1)).to eq(false)
              expect(valid?(nil, :a => 1)).to eq(false)
            end

            it 'treats symbols as keyword arguments and the rest as optional argument' do
              expect(valid?(nil, 'a' => 1)).to eq(true)
              expect(valid?(nil, 'a' => 1, :z => 3)).to eq(true)
              expect(valid?(nil, 'a' => 1, :b => 3)).to eq(false)
              expect(valid?(nil, 'a' => 1, :b => 2, :z => 3)).to eq(false)
            end

            it 'mentions the invalid keyword args in the error', :pending => RSpec::Support::Ruby.jruby? && !RSpec::Support::Ruby.jruby_9000? do
              expect(error_for(1, 2, :a => 0)).to eq("Invalid keyword arguments provided: a")
              expect(error_for(1, :a => 0)).to eq("Invalid keyword arguments provided: a")
              expect(error_for(1, 'a' => 0, :b => 0)).to eq("Invalid keyword arguments provided: b")
            end

            it 'describes invalid arity precisely' do
              expect(error_for()).to \
                eq("Wrong number of arguments. Expected 1 to 2, got 0.")
            end

            it 'does not blow up when given a BasicObject as the last arg' do
              expect(valid?(BasicObject.new)).to eq(true)
            end

            it 'does not mutate the provided args array' do
              args = [nil, nil, { :y => 1 }]
              described_class.new(signature, args).valid?
              expect(args).to eq([nil, nil, { :y => 1 }])
            end

            it 'mentions the arity and optional kw args in the description', :pending => RSpec::Support::Ruby.jruby? && !RSpec::Support::Ruby.jruby_9000? do
              expect(signature_description).to eq("arity of 1 to 2 and optional keyword args (:z)")
            end

            it "indicates the optional keyword args" do
              expect(signature.optional_kw_args).to contain_exactly(:z)
            end

            it "indicates it has no required keyword args" do
              expect(signature.required_kw_args).to eq([])
            end

            describe 'with an expectation object' do
              it 'matches the exact arity' do
                expect(validate_expectation 0).to eq(false)
                expect(validate_expectation 1).to eq(true)
                expect(validate_expectation 2).to eq(true)
              end

              it 'matches the exact range' do
                expect(validate_expectation 0, 1).to eq(false)
                expect(validate_expectation 1, 1).to eq(true)
                expect(validate_expectation 1, 2).to eq(true)
                expect(validate_expectation 1, 3).to eq(false)
              end

              it 'does not match unlimited arguments' do
                expect(validate_expectation :unlimited_args).to eq(false)
              end

              it 'matches optional keywords with the correct arity' do
                expect(validate_expectation :z).to eq(false)
                expect(validate_expectation 1, :z).to eq(true) # Are we OK with that?
                expect(validate_expectation 1, 2, :z).to eq(true)
                expect(validate_expectation 1, 2, :y).to eq(false)
              end

              it 'does not match invalid keywords' do
                expect(validate_expectation :w).to eq(false)

                expect(validate_expectation 2, :w).to eq(false)
              end

              it 'does not match arbitrary keywords' do
                expect(validate_expectation :arbitrary_kw_args).to eq(false)
              end
            end
          end
        end

        if RubyFeatures.required_kw_args_supported?
          describe 'a method with required keyword arguments' do
            eval <<-RUBY
              def arity_required_kw(x, y:, z:, a: 'default'); end
            RUBY

            let(:test_method) { method(:arity_required_kw) }

            it 'returns false unless all required keywords args are present' do
              expect(valid?(nil, :a => 0, :y => 1, :z => 2)).to eq(true)
              expect(valid?(nil, :a => 0, :y => 1)).to eq(false)
              expect(valid?(nil, nil, :a => 0, :y => 1, :z => 2)).to eq(false)
              expect(valid?(nil, nil)).to eq(false)
            end

            it 'mentions the missing required keyword args in the error' do
              expect(error_for(nil, :a => 0)).to \
                eq("Missing required keyword arguments: y, z")
            end

            it 'is described precisely when arity is wrong' do
              expect(error_for(nil, nil, :z => 0, :y => 1)).to \
                eq("Wrong number of arguments. Expected 1, got 2.")
            end

            it 'mentions the arity, optional kw args and required kw args in the description' do
              expect(signature_description).to \
                eq("arity of 1 and optional keyword args (:a) and required keyword args (:y, :z)")
            end

            it "indicates the optional keyword args" do
              expect(signature.optional_kw_args).to contain_exactly(:a)
            end

            it "indicates the required keyword args" do
              expect(signature.required_kw_args).to contain_exactly(:y, :z)
            end

            describe 'with an expectation object' do
              it 'does not match the exact arity without the required keywords' do
                expect(validate_expectation 0).to eq(false)
                expect(validate_expectation 1).to eq(false)
                expect(validate_expectation 1, :y).to eq(false)
                expect(validate_expectation 1, :z).to eq(false)
                expect(validate_expectation 2).to eq(false)
              end

              it 'does not match the range without the required keywords' do
                expect(validate_expectation 0, 1).to eq(false)
                expect(validate_expectation 1, 1).to eq(false)
                expect(validate_expectation 1, 1, :y).to eq(false)
                expect(validate_expectation 1, 1, :z).to eq(false)
                expect(validate_expectation 1, 2).to eq(false)
              end

              it 'matches the exact arity with the required keywords' do
                expect(validate_expectation 0, :y, :z).to eq(false)
                expect(validate_expectation 1, :y, :z).to eq(true)
                expect(validate_expectation 2, :y, :z).to eq(false)
              end

              it 'matches the range with the required keywords' do
                expect(validate_expectation 0, 1, :y, :z).to eq(false)
                expect(validate_expectation 1, 1, :y, :z).to eq(true)
                expect(validate_expectation 1, 2, :y, :z).to eq(false)
              end

              it 'does not match unlimited arguments' do
                expect(validate_expectation :unlimited_args).to eq(false)
                expect(validate_expectation :y, :z, :unlimited_args).to eq(false)
              end

              it 'matches optional keywords with the required keywords' do
                expect(validate_expectation 1, :a, :y, :z).to eq(true)
              end

              it 'does not match optional keywords without the required keywords' do
                expect(validate_expectation :a).to eq(false)
                expect(validate_expectation :a, :y).to eq(false)
                expect(validate_expectation :a, :z).to eq(false)

                expect(validate_expectation 1, :a).to eq(false)
                expect(validate_expectation 1, :a, :y).to eq(false)
                expect(validate_expectation 1, :a, :z).to eq(false)
              end

              it 'does not match invalid keywords' do
                expect(validate_expectation :w).to eq(false)
                expect(validate_expectation :w, :y, :z).to eq(false)

                expect(validate_expectation 1, :w).to eq(false)
                expect(validate_expectation 1, :w, :y, :z).to eq(false)
              end

              it 'does not match arbitrary keywords' do
                expect(validate_expectation :arbitrary_kw_args).to eq(false)
                expect(validate_expectation :y, :z, :arbitrary_kw_args).to eq(false)
              end
            end
          end

          describe 'a method with required keyword arguments and a splat' do
            eval <<-RUBY
              def arity_required_kw_splat(w, *x, y:, z:, a: 'default'); end
            RUBY

            let(:test_method) { method(:arity_required_kw_splat) }

            it 'returns false unless all required keywords args are present' do
              expect(valid?(nil, :a => 0, :y => 1, :z => 2)).to eq(true)
              expect(valid?(nil, :a => 0, :y => 1)).to eq(false)
              expect(valid?(nil, nil, :a => 0, :y => 1, :z => 2)).to eq(true)
              expect(valid?(nil, nil, nil)).to eq(false)
              expect(valid?).to eq(false)
            end

            it 'mentions missing required keyword args in the error' do
              expect(error_for(nil, :y => 1)).to \
                eq("Missing required keyword arguments: z")
            end

            it 'mentions the arity, optional kw args and required kw args in the description' do
              expect(signature_description).to \
                eq("arity of 1 or more and optional keyword args (:a) and required keyword args (:y, :z)")
            end

            describe 'with an expectation object' do
              it 'does not match a value from the lower bound upwards' do
                expect(validate_expectation 0).to eq(false)
                expect(validate_expectation 1).to eq(false)
                expect(validate_expectation 1, :y).to eq(false)
                expect(validate_expectation 1, :z).to eq(false)
                expect(validate_expectation 2).to eq(false)
              end

              it 'does not match a range from the lower bound upwards' do
                expect(validate_expectation 0, 1).to eq(false)
                expect(validate_expectation 1, 1).to eq(false)
                expect(validate_expectation 1, 1, :y).to eq(false)
                expect(validate_expectation 1, 1, :z).to eq(false)
                expect(validate_expectation 1, 2).to eq(false)
              end

              it 'matches a value from the lower bound upwards with the required keywords' do
                expect(validate_expectation 0, :y, :z).to eq(false)
                expect(validate_expectation 1, :y, :z).to eq(true)
                expect(validate_expectation 2, :y, :z).to eq(true)
                expect(validate_expectation 3, :y, :z).to eq(true)
              end

              it 'matches a range from the lower bound upwards with the required keywords' do
                expect(validate_expectation 0, 1, :y, :z).to eq(false)
                expect(validate_expectation 1, 1, :y, :z).to eq(true)
                expect(validate_expectation 1, 2, :y, :z).to eq(true)
                expect(validate_expectation 3, 4, :y, :z).to eq(true)
                expect(validate_expectation 3, 2 ** 31, :y, :z).to eq(true)
              end

              it 'matches unlimited arguments with the minimum arity and the required keywords' do
                expect(validate_expectation :unlimited_args).to eq(false)
                expect(validate_expectation 1, :unlimited_args).to eq(false)
                expect(validate_expectation :y, :z, :unlimited_args).to eq(false)
                expect(validate_expectation 1, :y, :z, :unlimited_args).to eq(true)
              end

              it 'matches optional keywords with the required keywords' do
                expect(validate_expectation 1, :a, :y, :z).to eq(true)
              end

              it 'does not match optional keywords without the required keywords' do
                expect(validate_expectation :a).to eq(false)
                expect(validate_expectation :a, :y).to eq(false)
                expect(validate_expectation :a, :z).to eq(false)

                expect(validate_expectation 1, :a).to eq(false)
                expect(validate_expectation 1, :a, :y).to eq(false)
                expect(validate_expectation 1, :a, :z).to eq(false)
              end

              it 'does not match invalid keywords' do
                expect(validate_expectation :w).to eq(false)
                expect(validate_expectation :w, :y, :z).to eq(false)

                expect(validate_expectation 1, :w).to eq(false)
                expect(validate_expectation 1, :w, :y, :z).to eq(false)
              end

              it 'does not match arbitrary keywords' do
                expect(validate_expectation :arbitrary_kw_args).to eq(false)
                expect(validate_expectation :y, :z, :arbitrary_kw_args).to eq(false)
              end
            end
          end

          describe 'a method with required keyword arguments and a keyword arg splat' do
            eval <<-RUBY
              def arity_kw_arg_splat(x:, **rest); end
            RUBY

            let(:test_method) { method(:arity_kw_arg_splat) }

            it 'allows extra undeclared keyword args' do
              expect(valid?(:x => 1)).to eq(true)
              expect(valid?(:x => 1, :y => 2)).to eq(true)
            end

            it 'mentions missing required keyword args in the error' do
              expect(error_for(:y => 1)).to \
                eq("Missing required keyword arguments: x")
            end

            it 'mentions the required kw args and keyword splat in the description' do
              expect(signature_description).to \
                eq("required keyword args (:x) and any additional keyword args")
            end

            describe 'with an expectation object' do
              it 'does not match the exact arity without the required keywords' do
                expect(validate_expectation 0).to eq(false)
                expect(validate_expectation 1).to eq(false)
              end

              it 'does not match the exact range without the required keywords' do
                expect(validate_expectation 0, 0).to eq(false)
                expect(validate_expectation 0, 1).to eq(false)
              end

              it 'matches the exact arity with the required keywords' do
                expect(validate_expectation 0, :x).to eq(true)
              end

              it 'does matches the exact range without the required keywords' do
                expect(validate_expectation 0, 0, :x).to eq(true)
                expect(validate_expectation 0, 1, :x).to eq(false)
              end

              it 'does not match unlimited arguments' do
                expect(validate_expectation :unlimited_args).to eq(false)
                expect(validate_expectation :x, :unlimited_args).to eq(false)
              end

              it 'matches arbitrary keywords with the required keywords' do
                expect(validate_expectation 0, :x, :u, :v).to eq(true)
              end

              it 'does not match arbitrary keywords without the required keywords' do
                expect(validate_expectation :a).to eq(false)

                expect(validate_expectation 0, :a).to eq(false)
              end

              it 'matches arbitrary keywords with the required keywords' do
                expect(validate_expectation :arbitrary_kw_args).to eq(false)
                expect(validate_expectation :x, :arbitrary_kw_args).to eq(true)
              end
            end
          end

          describe 'a method with a required arg and a keyword arg splat' do
            eval <<-RUBY
              def arity_kw_arg_splat(x, **rest); end
            RUBY

            let(:test_method) { method(:arity_kw_arg_splat) }

            it 'allows a single arg and any number of keyword args' do
              expect(valid?(nil)).to eq(true)
              expect(valid?(nil, :x => 1)).to eq(true)
              expect(valid?(nil, :x => 1, :y => 2)).to eq(true)
              expect(valid?(:x => 1)).to eq(true)
              expect(valid?(nil, {})).to eq(true)

              expect(valid?).to eq(false)
              expect(valid?(nil, nil)).to eq(false)
              expect(valid?(nil, nil, :x => 1)).to eq(false)
            end

            it 'describes the arity precisely' do
              expect(error_for()).to \
                eq("Wrong number of arguments. Expected 1, got 0.")
            end

            it 'mentions the required kw args and keyword splat in the description' do
              expect(signature_description).to \
                eq("arity of 1 and any additional keyword args")
            end

            describe 'with an expectation object' do
              it 'matches the exact arity' do
                expect(validate_expectation 0).to eq(false)
                expect(validate_expectation 1).to eq(true)
                expect(validate_expectation 2).to eq(false)
              end

              it 'matches the exact range' do
                expect(validate_expectation 0, 0).to eq(false)
                expect(validate_expectation 0, 1).to eq(false)
                expect(validate_expectation 1, 1).to eq(true)
                expect(validate_expectation 1, 2).to eq(false)
                expect(validate_expectation 2, 2).to eq(false)
              end

              it 'does not match unlimited arguments' do
                expect(validate_expectation :unlimited_args).to eq(false)
                expect(validate_expectation 1, :unlimited_args).to eq(false)
              end

              it 'matches unlisted keywords with the required arity' do
                expect(validate_expectation 1, :u, :v).to eq(true)
              end

              it 'matches unlisted keywords with the exact range' do
                expect(validate_expectation 1, 1, :u, :v).to eq(true)
              end

              it 'matches arbitrary keywords with the required arity' do
                expect(validate_expectation :arbitrary_kw_args).to eq(false)
                expect(validate_expectation 1, :arbitrary_kw_args).to eq(true)
              end
            end
          end
        end

        describe 'a method with a block' do
          def arity_block(_, &block); end

          let(:test_method) { method(:arity_block) }

          it 'does not count the block as a parameter' do
            expect(valid_non_kw_args?(1)).to eq(true)
            expect(valid_non_kw_args?(2)).to eq(false)
          end

          it 'describes the arity precisely' do
            expect(error_description).to eq("1")
          end
        end

        describe 'an `attr_writer` method' do
          attr_writer :foo
          let(:test_method) { method(:foo=) }

          it 'validates against a single argument' do
            expect(valid_non_kw_args?(1)).to eq true
          end

          it 'fails validation against 0 arguments' do
            expect(valid_non_kw_args?(0)).to eq false
          end

          it 'fails validation against 2 arguments' do
            expect(valid_non_kw_args?(2)).to eq false
          end
        end

        if Ruby.jruby?
          describe 'a single-argument Java method' do
            let(:test_method) { Java::JavaLang::String.instance_method(:char_at) }

            it 'validates against a single argument' do
              expect(valid_non_kw_args?(1)).to eq true
            end

            it 'fails validation against 0 arguments' do
              expect(valid_non_kw_args?(0)).to eq false
            end

            it 'fails validation against 2 arguments' do
              expect(valid_non_kw_args?(2)).to eq false
            end
          end
        end
      end

      let(:fake_matcher) { Object.new }
      let(:fake_matcher_def) { lambda {|x| fake_matcher == x }}

      before do
        RSpec::Support.register_matcher_definition(&fake_matcher_def)
      end

      after do
        RSpec::Support.deregister_matcher_definition(&fake_matcher_def)
      end

      describe MethodSignatureExpectation do
        describe '#max_count' do
          it { expect(subject).to respond_to(:max_count).with(0).arguments }
        end

        describe '#max_count=' do
          it { expect(subject).to respond_to(:max_count=).with(1).argument }

          describe 'with nil' do
            before(:each) { subject.max_count = 5 }

            it { expect { subject.max_count = nil }.to change(subject, :max_count).to be(nil) }
          end

          describe 'with a positive integer' do
            let(:value) { 7 }

            it { expect { subject.max_count = value }.to change(subject, :max_count).to eq(value) }
          end

          describe 'with zero' do
            it { expect { subject.max_count = 0 }.to change(subject, :max_count).to eq(0) }
          end

          describe 'with a negative integer value' do
            it 'should raise an error' do
              expect { subject.max_count = -1 }.to raise_error ArgumentError
            end
          end

          describe 'with a non-integer value' do
            it 'should raise an error' do
              expect { subject.max_count = :many }.to raise_error ArgumentError
            end
          end
        end

        describe '#min_count' do
          it { expect(subject).to respond_to(:min_count).with(0).arguments }
        end

        describe '#min_count=' do
          it { expect(subject).to respond_to(:min_count=).with(1).argument }

          describe 'with nil' do
            before(:each) { subject.min_count = 5 }

            it { expect { subject.min_count = nil }.to change(subject, :min_count).to be(nil) }
          end

          describe 'with a positive integer' do
            let(:value) { 7 }

            it { expect { subject.min_count = value }.to change(subject, :min_count).to eq(value) }
          end

          describe 'with zero' do
            it { expect { subject.min_count = 0 }.to change(subject, :min_count).to eq(0) }
          end

          describe 'with a negative integer value' do
            it 'should raise an error' do
              expect { subject.min_count = -1 }.to raise_error ArgumentError
            end
          end

          describe 'with a non-integer value' do
            it 'should raise an error' do
              expect { subject.min_count = :many }.to raise_error ArgumentError
            end
          end
        end

        describe '#empty?' do
          it { expect(subject).to respond_to(:empty?).with(0).arguments }

          it { expect(subject.empty?).to eq(true) }

          describe 'with a count expectation' do
            before(:each) { subject.min_count = 5 }

            it { expect(subject.empty?).to eq(false) }
          end

          describe 'with a keywords expectation' do
            before(:each) { subject.keywords << :greetings << :programs }

            it { expect(subject.empty?).to eq(false) }
          end
        end

        describe '#expect_arbitrary_keywords' do
          it { expect(subject).to respond_to(:expect_arbitrary_keywords).with(0).arguments }

          it 'should default to false' do
            expect(described_class.new.expect_arbitrary_keywords).to eq(false)
          end
        end

        describe '#expect_arbitrary_keywords=' do
          it { expect(subject).to respond_to(:expect_arbitrary_keywords=).with(1).argument }

          describe 'with true' do
            it { expect { subject.expect_arbitrary_keywords = true }.to change(subject, :expect_arbitrary_keywords).to eq(true) }
          end
        end

        describe '#expect_unlimited_arguments' do
          it { expect(subject).to respond_to(:expect_unlimited_arguments).with(0).arguments }

          it 'should default to false' do
            expect(described_class.new.expect_unlimited_arguments).to eq(false)
          end
        end

        describe '#expect_unlimited_arguments=' do
          it { expect(subject).to respond_to(:expect_unlimited_arguments=).with(1).argument }

          describe 'with true' do
            it { expect { subject.expect_unlimited_arguments = true }.to change(subject, :expect_unlimited_arguments).to eq(true) }
          end
        end

        describe '#keywords' do
          it { expect(subject).to respond_to(:keywords).with(0).arguments }

          it { expect(subject.keywords).to eq(Array.new) }
        end

        describe '#keywords=' do
          it { expect(subject).to respond_to(:keywords=).with(1).argument }

          describe 'with nil' do
            before(:each) { subject.keywords = [:greetings, :programs] }

            it { expect { subject.keywords = nil }.to change(subject, :keywords).to eq(Array.new) }
          end

          describe 'with an array' do
            let(:keywords) { [:greetings, :programs] }

            it { expect { subject.keywords = keywords }.to change(subject, :keywords).to eq(keywords) }
          end
        end
      end

      describe StrictSignatureVerifier do
        it_behaves_like 'a method verifier'

        if RubyFeatures.kw_args_supported?
          describe 'providing a matcher for optional keyword arguments' do
            eval <<-RUBY
              def arity_kw(x, y:1); end
            RUBY

            let(:test_method) { method(:arity_kw) }

            it 'is not allowed' do
              expect(valid?(nil, fake_matcher)).to eq(false)
            end
          end
        end

        if RubyFeatures.required_kw_args_supported?
          describe 'providing a matcher for required keyword arguments' do
            eval <<-RUBY
              def arity_kw_required(x, y:); end
            RUBY

            let(:test_method) { method(:arity_kw_required) }

            it 'is not allowed' do
              expect(valid?(nil, fake_matcher)).to eq(false)
            end
          end
        end
      end

      describe LooseSignatureVerifier do
        it_behaves_like 'a method verifier'

        if RubyFeatures.kw_args_supported?
          describe 'for optional keyword arguments' do
            eval <<-RUBY
              def arity_kw(x, y:1, z:2); end
            RUBY

            let(:test_method) { method(:arity_kw) }

            it 'allows a matcher' do
              expect(valid?(nil, fake_matcher)).to eq(true)
            end

            it 'allows a matcher only for positional arguments' do
              expect(valid?(fake_matcher)).to eq(true)
            end
          end
        end

        if RubyFeatures.required_kw_args_supported?
          describe 'providing a matcher for required keyword arguments' do
            eval <<-RUBY
              def arity_kw_required(x, y:); end
            RUBY

            let(:test_method) { method(:arity_kw_required) }

            it 'is allowed' do
              expect(valid?(nil, fake_matcher)).to eq(true)
            end
          end
        end
      end
    end
  end
end
