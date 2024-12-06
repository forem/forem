describe KnapsackPro::QueueAllocator do
  let(:fast_and_slow_test_files_to_run) { double }
  let(:fallback_mode_test_files) { double }
  let(:ci_node_total) { double }
  let(:ci_node_index) { double }
  let(:ci_node_build_id) { double }
  let(:repository_adapter) { instance_double(KnapsackPro::RepositoryAdapters::EnvAdapter, commit_hash: double, branch: double) }

  let(:queue_allocator) do
    described_class.new(
      fast_and_slow_test_files_to_run: fast_and_slow_test_files_to_run,
      fallback_mode_test_files: fallback_mode_test_files,
      ci_node_total: ci_node_total,
      ci_node_index: ci_node_index,
      ci_node_build_id: ci_node_build_id,
      repository_adapter: repository_adapter
    )
  end

  describe '#test_file_paths' do
    let(:executed_test_files) { [] }
    let(:response) { double }
    let(:api_code) { nil }

    subject { queue_allocator.test_file_paths(can_initialize_queue, executed_test_files) }

    shared_examples_for 'when connection to API failed (fallback mode)' do
      context 'when fallback mode is disabled' do
        before do
          expect(KnapsackPro::Config::Env).to receive(:fallback_mode_enabled?).and_return(false)
        end

        it do
          expect { subject }.to raise_error(RuntimeError, 'Fallback Mode was disabled with KNAPSACK_PRO_FALLBACK_MODE_ENABLED=false. Please restart this CI node to retry tests. Most likely Fallback Mode was disabled due to https://knapsackpro.com/perma/ruby/queue-mode-connection-error-with-fallback-enabled-false')
        end
      end

      context 'when CI node retry count > 0' do
        before do
          expect(KnapsackPro::Config::Env).to receive(:ci_node_retry_count).and_return(1)
        end

        context 'when fixed_queue_split=true' do
          before do
            expect(KnapsackPro::Config::Env).to receive(:fixed_queue_split).and_return(true)
          end

          it do
            expect { subject }.to raise_error(RuntimeError, 'knapsack_pro gem could not connect to Knapsack Pro API and the Fallback Mode cannot be used this time. Running tests in Fallback Mode are not allowed for retried parallel CI node to avoid running the wrong set of tests. Please manually retry this parallel job on your CI server then knapsack_pro gem will try to connect to Knapsack Pro API again and will run a correct set of tests for this CI node. Learn more https://knapsackpro.com/perma/ruby/queue-mode-connection-error-with-fallback-enabled-true-and-positive-retry-count')
          end
        end

        context 'when fixed_queue_split=false' do
          before do
            expect(KnapsackPro::Config::Env).to receive(:fixed_queue_split).and_return(false)
          end

          it do
            expect { subject }.to raise_error(RuntimeError, 'knapsack_pro gem could not connect to Knapsack Pro API and the Fallback Mode cannot be used this time. Running tests in Fallback Mode are not allowed for retried parallel CI node to avoid running the wrong set of tests. Please manually retry this parallel job on your CI server then knapsack_pro gem will try to connect to Knapsack Pro API again and will run a correct set of tests for this CI node. Learn more https://knapsackpro.com/perma/ruby/queue-mode-connection-error-with-fallback-enabled-true-and-positive-retry-count Please ensure you have set KNAPSACK_PRO_FIXED_QUEUE_SPLIT=true to allow Knapsack Pro API remember the recorded CI node tests so when you retry failed tests on the CI node then the same set of tests will be executed. See more https://knapsackpro.com/perma/ruby/fixed-queue-split')
          end
        end
      end

      context 'when fallback mode started' do
        before do
          test_flat_distributor = instance_double(KnapsackPro::TestFlatDistributor)
          expect(KnapsackPro::TestFlatDistributor).to receive(:new).with(fallback_mode_test_files, ci_node_total).and_return(test_flat_distributor)
          expect(test_flat_distributor).to receive(:test_files_for_node).with(ci_node_index).and_return([
            { 'path' => 'c_spec.rb' },
            { 'path' => 'd_spec.rb' },
          ])
        end

        context 'when no test files were executed yet' do
          let(:executed_test_files) { [] }

          it 'enables fallback mode and returns fallback test files' do
            expect(subject).to eq ['c_spec.rb', 'd_spec.rb']
          end
        end

        context 'when test files were already executed' do
          let(:executed_test_files) { ['c_spec.rb', 'additional_executed_spec.rb'] }

          it 'enables fallback mode and returns fallback test files' do
            expect(subject).to eq ['d_spec.rb']
          end
        end
      end
    end

    context 'when can_initialize_queue=true' do
      let(:can_initialize_queue) { true }

      before do
        encrypted_branch = double
        expect(KnapsackPro::Crypto::BranchEncryptor).to receive(:call).with(repository_adapter.branch).and_return(encrypted_branch)

        action = double
        expect(KnapsackPro::Client::API::V1::Queues).to receive(:queue).with(
          can_initialize_queue: can_initialize_queue,
          attempt_connect_to_queue: true, # when can_initialize_queue=true then expect attempt_connect_to_queue=true
          commit_hash: repository_adapter.commit_hash,
          branch: encrypted_branch,
          node_total: ci_node_total,
          node_index: ci_node_index,
          node_build_id: ci_node_build_id,
          test_files: nil, # when attempt_connect_to_queue=true then expect test_files is nil to make fast request to API
        ).and_return(action)

        connection = instance_double(KnapsackPro::Client::Connection,
                                     call: response,
                                     success?: success?,
                                     errors?: errors?,
                                     api_code: api_code)
        expect(KnapsackPro::Client::Connection).to receive(:new).with(action).and_return(connection)
      end

      context 'when successful request to API' do
        let(:success?) { true }

        context 'when response has errors' do
          let(:errors?) { true }

          it do
            expect { subject }.to raise_error(ArgumentError)
          end
        end

        context 'when response has no errors' do
          let(:errors?) { false }

          context 'when response returns test files (successful attempt to connect to queue already existing on the API side)' do
            let(:response) do
              {
                'test_files' => [
                  { 'path' => 'a_spec.rb' },
                  { 'path' => 'b_spec.rb' },
                ]
              }
            end

            before do
              expect(KnapsackPro::Crypto::Decryptor).to receive(:call).with(fast_and_slow_test_files_to_run, response['test_files']).and_call_original
            end

            it { should eq ['a_spec.rb', 'b_spec.rb'] }
          end

          context 'when the response has the API code=ATTEMPT_CONNECT_TO_QUEUE_FAILED' do
            let(:api_code) { 'ATTEMPT_CONNECT_TO_QUEUE_FAILED' }

            before do
              encrypted_branch = double
              expect(KnapsackPro::Crypto::BranchEncryptor).to receive(:call).with(repository_adapter.branch).and_return(encrypted_branch)

              encrypted_test_files = double
              expect(KnapsackPro::Crypto::Encryptor).to receive(:call).with(fast_and_slow_test_files_to_run).and_return(encrypted_test_files)

              # 2nd request is no more an attempt to connect to queue.
              # We want to try to initalize a new queue so we will also send list of test files from disk.
              action = double
              expect(KnapsackPro::Client::API::V1::Queues).to receive(:queue).with(
                can_initialize_queue: can_initialize_queue,
                attempt_connect_to_queue: false,
                commit_hash: repository_adapter.commit_hash,
                branch: encrypted_branch,
                node_total: ci_node_total,
                node_index: ci_node_index,
                node_build_id: ci_node_build_id,
                test_files: encrypted_test_files,
              ).and_return(action)

              connection = instance_double(KnapsackPro::Client::Connection,
                                           call: response2,
                                           success?: response2_success?,
                                           errors?: response2_errors?,
                                           api_code: nil)
              expect(KnapsackPro::Client::Connection).to receive(:new).with(action).and_return(connection)
            end

            context 'when successful 2nd request to API' do
              let(:response2_success?) { true }

              context 'when 2nd response has errors' do
                let(:response2_errors?) { true }
                let(:response2) { nil }

                it do
                  expect { subject }.to raise_error(ArgumentError)
                end
              end

              context 'when 2nd response has no errors' do
                let(:response2_errors?) { false }

                context 'when 2nd response returns test files (successfully initialized a new queue or connected to an existing queue on the API side)' do
                  let(:response2) do
                    {
                      'test_files' => [
                        { 'path' => 'a_spec.rb' },
                        { 'path' => 'b_spec.rb' },
                      ]
                    }
                  end

                  before do
                    expect(KnapsackPro::Crypto::Decryptor).to receive(:call).with(fast_and_slow_test_files_to_run, response2['test_files']).and_call_original
                  end

                  it { should eq ['a_spec.rb', 'b_spec.rb'] }
                end
              end
            end

            context 'when not successful 2nd request to API' do
              let(:response2_success?) { false }
              let(:response2_errors?) { false }
              let(:response2) { nil }

              it_behaves_like 'when connection to API failed (fallback mode)'
            end
          end
        end
      end

      context 'when not successful request to API' do
        let(:success?) { false }
        let(:errors?) { false }

        it_behaves_like 'when connection to API failed (fallback mode)'
      end
    end

    context 'when can_initialize_queue=false' do
      let(:can_initialize_queue) { false }
      let(:api_code) { nil }

      before do
        encrypted_branch = double
        expect(KnapsackPro::Crypto::BranchEncryptor).to receive(:call).with(repository_adapter.branch).and_return(encrypted_branch)

        action = double
        expect(KnapsackPro::Client::API::V1::Queues).to receive(:queue).with(
          can_initialize_queue: can_initialize_queue,
          attempt_connect_to_queue: false, # when can_initialize_queue=false then expect attempt_connect_to_queue=false
          commit_hash: repository_adapter.commit_hash,
          branch: encrypted_branch,
          node_total: ci_node_total,
          node_index: ci_node_index,
          node_build_id: ci_node_build_id,
          test_files: nil, # when can_initialize_queue=false then expect test_files is nil to make fast request to API
        ).and_return(action)

        connection = instance_double(KnapsackPro::Client::Connection,
                                     call: response,
                                     success?: success?,
                                     errors?: errors?,
                                     api_code: api_code)
        expect(KnapsackPro::Client::Connection).to receive(:new).with(action).and_return(connection)
      end

      context 'when successful request to API' do
        let(:success?) { true }

        context 'when response has errors' do
          let(:errors?) { true }

          it do
            expect { subject }.to raise_error(ArgumentError)
          end
        end

        context 'when response has no errors' do
          let(:errors?) { false }

          context 'when response returns test files (successful attempt to connect to queue already existing on the API side)' do
            let(:response) do
              {
                'test_files' => [
                  { 'path' => 'a_spec.rb' },
                  { 'path' => 'b_spec.rb' },
                ]
              }
            end

            before do
              expect(KnapsackPro::Crypto::Decryptor).to receive(:call).with(fast_and_slow_test_files_to_run, response['test_files']).and_call_original
            end

            it { should eq ['a_spec.rb', 'b_spec.rb'] }
          end
        end
      end

      context 'when not successful request to API' do
        let(:success?) { false }
        let(:errors?) { false }

        it_behaves_like 'when connection to API failed (fallback mode)'
      end
    end
  end
end
