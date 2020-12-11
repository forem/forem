module RSpec
  module Core
    class Example
      RSpec.describe ExecutionResult do
        it "supports ruby 2.1's `to_h` protocol" do
          er = ExecutionResult.new
          er.run_time = 17
          er.pending_message = "just because"

          expect(er.to_h).to include(
            :run_time => 17,
            :pending_message => "just because"
          )
        end

        it 'includes all defined attributes in the `to_h` hash even if not set' do
          expect(ExecutionResult.new.to_h).to include(
            :status => nil,
            :pending_message => nil
          )
        end

        it 'provides a `pending_fixed?` predicate' do
          er = ExecutionResult.new
          expect { er.pending_fixed = true }.to change(er, :pending_fixed?).from(false).to(true)
        end

        describe "backwards compatibility" do
          it 'supports indexed access like a hash' do
            er = ExecutionResult.new
            er.started_at = (started_at = ::Time.utc(2014, 3, 1, 12, 30))
            expect_deprecation_with_call_site(__FILE__, __LINE__ + 1, /execution_result/)
            expect(er[:started_at]).to eq(started_at)
          end

          it 'supports indexed updates like a hash' do
            er = ExecutionResult.new
            expect_deprecation_with_call_site(__FILE__, __LINE__ + 1, /execution_result/)
            er[:started_at] = (started_at = ::Time.utc(2014, 3, 1, 12, 30))
            expect(er.started_at).to eq(started_at)
          end

          it 'can get and set user defined attributes like with a hash' do
            er = ExecutionResult.new
            allow_deprecation
            expect { er[:foo] = 3 }.to change { er[:foo] }.from(nil).to(3)
            expect(er.to_h).to include(:foo => 3)
          end

          it 'supports `update` like a hash' do
            er = ExecutionResult.new
            expect_deprecation_with_call_site(__FILE__, __LINE__ + 1, /execution_result/)
            er.update(:pending_message => "some message", :exception => ArgumentError.new)
            expect(er.pending_message).to eq("some message")
            expect(er.exception).to be_a(ArgumentError)
          end

          it 'can set undefined attribute keys through any hash mutation method' do
            allow_deprecation
            er = ExecutionResult.new
            er.update(:pending_message => "msg", :foo => 3)
            expect(er.to_h).to include(:pending_message => "msg", :foo => 3)
          end

          it 'supports `merge` like a hash' do
            er = ExecutionResult.new
            er.exception = ArgumentError.new
            er.pending_message = "just because"

            expect_deprecation_with_call_site(__FILE__, __LINE__ + 1, /execution_result/)
            merged = er.merge(:exception => NotImplementedError.new, :foo => 3)

            expect(merged).to include(
              :exception => an_instance_of(NotImplementedError),
              :pending_message => "just because",
              :foo => 3
            )

            expect(er.exception).to be_an(ArgumentError)
          end

          it 'supports blocks for hash methods that support one' do
            er = ExecutionResult.new
            expect_deprecation_with_call_site(__FILE__, __LINE__ + 1, /execution_result/)
            expect(er.fetch(:foo) { 3 }).to eq(3)
          end

          # It's IndexError on 1.8.7, KeyError on 1.9+
          fetch_not_found_error_class = defined?(::KeyError) ? ::KeyError : ::IndexError

          specify '#fetch treats unset properties the same as a hash does' do
            allow_deprecation
            er = ExecutionResult.new
            expect { er.fetch(:pending_message) }.to raise_error(fetch_not_found_error_class)
            er.pending_message = "some msg"
            expect(er.fetch(:pending_message)).to eq("some msg")
          end

          describe "status" do
            it 'returns a string when accessed like a hash' do
              er = ExecutionResult.new
              expect(er[:status]).to eq(nil)
              er.status = :failed
              expect(er[:status]).to eq("failed")
            end

            it "sets the status to a symbol when assigned as a string via the hash interface" do
              er = ExecutionResult.new
              er[:status] = "failed"
              expect(er.status).to eq(:failed)
              er[:status] = nil
              expect(er.status).to eq(nil)
            end

            it "is presented as a string when included in returned hashes" do
              er = ExecutionResult.new
              er.status = :failed
              expect(er.merge(:foo => 3)).to include(:status => "failed", :foo => 3)

              er.status = nil
              expect(er.merge(:foo => 3)).to include(:status => nil, :foo => 3)
            end

            it "is updated to a symbol when updated as a string via `update`" do
              er = ExecutionResult.new
              er.update(:status => "passed")
              expect(er.status).to eq(:passed)
            end

            it 'is presented as a symbol in `to_h`' do
              er = ExecutionResult.new
              er.status = :failed
              expect(er.to_h).to include(:status => :failed)
            end
          end
        end
      end
    end
  end
end
