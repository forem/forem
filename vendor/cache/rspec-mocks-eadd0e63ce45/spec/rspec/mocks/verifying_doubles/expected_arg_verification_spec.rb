require 'support/doubled_classes'

module RSpec
  module Mocks
    RSpec.describe 'Expected argument verification (when `#with` is called)' do
      # Note: these specs here aren't meant to be exhaustive. The specs in
      # rspec-support for the method signature verifier are. Here we are just
      # covering the code paths within the `with` implementation, including
      # the special handling for `any_args` and `no_args`.
      context "when doubling an unloaded class" do
        it 'allows any arguments' do
          expect(defined?(UnloadedClass)).to be_falsey
          inst_dbl = instance_double("UnloadedClass")

          expect {
            expect(inst_dbl).to receive(:message).with(:foo, :bar, :bazz)
          }.not_to raise_error

          reset inst_dbl
        end
      end

      context "when doubling a loaded class" do
        let(:dbl) { instance_double(LoadedClass) }
        after { reset dbl }

        context "when `any_args` is used" do
          context "as the only argument" do
            it "is allowed regardless of how many args the method requires" do
              expect {
                expect(dbl).to receive(:instance_method_with_two_args).with(any_args)
              }.not_to raise_error
            end
          end

          context "as the first argument, with too many additional args" do
            it "is disallowed" do
              expect {
                expect(dbl).to receive(:instance_method_with_two_args).with(any_args, 1, 2, 3)
              }.to fail_with("Wrong number of arguments. Expected 2, got 3.")
            end
          end

          context "as the first argument, with an allowed number of additional args" do
            it "is allowed" do
              expect {
                expect(dbl).to receive(:instance_method_with_two_args).with(any_args, 1, 2)
              }.not_to raise_error

              expect {
                expect(dbl).to receive(:instance_method_with_two_args).with(any_args, 1)
              }.not_to raise_error
            end
          end
        end

        context "when `no_args` is used" do
          it "allows a method expectation on a method that accepts no arguments" do
            expect(LoadedClass.instance_method(:defined_instance_method).arity).to eq(0)

            expect {
              expect(dbl).to receive(:defined_instance_method).with(no_args)
            }.not_to raise_error
          end

          it "allows a method expectation on a method that has defaults for all arguments" do
            expect {
              expect(dbl).to receive(:instance_method_with_only_defaults).with(no_args)
            }.not_to raise_error
          end

          it "does not allow a method expectation on a method that has required arguments" do
            expect {
              expect(dbl).to receive(:instance_method_with_two_args).with(no_args)
            }.to fail_with("Wrong number of arguments. Expected 2, got 0.")
          end

          if RSpec::Support::RubyFeatures.required_kw_args_supported?
            context "for a method with required keyword args" do
              it 'covers the required args when `any_args` is last' do
                expect {
                  expect(dbl).to receive(:kw_args_method).with(1, any_args)
                }.not_to raise_error
              end

              it 'does not cover the required args when there are args after `any_args`' do
                expect {
                  # Use eval to avoid syntax error on 1.8 and 1.9
                  eval("expect(dbl).to receive(:kw_args_method).with(any_args, optional_arg: 3)")
                }.to fail_with("Missing required keyword arguments: required_arg")
              end
            end
          end
        end

        if RSpec::Support::RubyFeatures.required_kw_args_supported?
          it 'does not cover required args when `any_args` is not used' do
            expect {
              expect(dbl).to receive(:kw_args_method).with(anything)
            }.to fail_with("Missing required keyword arguments: required_arg")
          end
        end

        context "when a list of args is provided" do
          it "allows a method expectation when the arity matches" do
            expect {
              expect(dbl).to receive(:instance_method_with_two_args).with(1, 2)
            }.not_to raise_error
          end

          it "does not allow a method expectation with an arity mismatch" do
            expect {
              expect(dbl).to receive(:instance_method_with_two_args).with(1, 2, 3)
            }.to fail_with("Wrong number of arguments. Expected 2, got 3.")
          end
        end

        context "when `with` is called with no args" do
          it "fails with an error suggesting the user use `no_args` instead" do
            expect {
              expect(dbl).to receive(:instance_method_with_two_args).with
            }.to raise_error(ArgumentError, /no_args/)
          end
        end
      end
    end
  end
end
