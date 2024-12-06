# frozen_string_literal: true

module KnapsackPro
  module Client
    module API
      module V1
        class BuildDistributions < Base
          TEST_SUITE_SPLIT_CACHE_MISS_CODE = 'TEST_SUITE_SPLIT_CACHE_MISS'

          class << self
            def subset(args)
              request_hash = {
                :fixed_test_suite_split => KnapsackPro::Config::Env.fixed_test_suite_split,
                :cache_read_attempt => args.fetch(:cache_read_attempt),
                :commit_hash => args.fetch(:commit_hash),
                :branch => args.fetch(:branch),
                :node_total => args.fetch(:node_total),
                :node_index => args.fetch(:node_index),
                :ci_build_id => KnapsackPro::Config::Env.ci_node_build_id,
                :user_seat => KnapsackPro::Config::Env.masked_user_seat,
                :build_author => KnapsackPro::RepositoryAdapters::GitAdapter.new.build_author,
                :commit_authors => KnapsackPro::RepositoryAdapters::GitAdapter.new.commit_authors,
              }

              unless request_hash[:cache_read_attempt]
                request_hash.merge!({
                  :test_files => args.fetch(:test_files)
                })
              end

              action_class.new(
                endpoint_path: '/v1/build_distributions/subset',
                http_method: :post,
                request_hash: request_hash
              )
            end

            def last(args)
              action_class.new(
                endpoint_path: '/v1/build_distributions/last',
                http_method: :get,
                request_hash: {
                  :commit_hash => args.fetch(:commit_hash),
                  :branch => args.fetch(:branch),
                  :node_total => args.fetch(:node_total),
                  :node_index => args.fetch(:node_index),
                }
              )
            end
          end
        end
      end
    end
  end
end
