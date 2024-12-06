# frozen_string_literal: true

module KnapsackPro
  module Client
    module API
      module V1
        class Queues < Base
          CODE_ATTEMPT_CONNECT_TO_QUEUE_FAILED = 'ATTEMPT_CONNECT_TO_QUEUE_FAILED'

          class << self
            def queue(args)
              request_hash = {
                :fixed_queue_split => KnapsackPro::Config::Env.fixed_queue_split,
                :can_initialize_queue => args.fetch(:can_initialize_queue),
                :attempt_connect_to_queue => args.fetch(:attempt_connect_to_queue),
                :commit_hash => args.fetch(:commit_hash),
                :branch => args.fetch(:branch),
                :node_total => args.fetch(:node_total),
                :node_index => args.fetch(:node_index),
                :node_build_id => KnapsackPro::Config::Env.ci_node_build_id,
                :user_seat => KnapsackPro::Config::Env.masked_user_seat,
              }

              if request_hash[:can_initialize_queue] && !request_hash[:attempt_connect_to_queue]
                request_hash.merge!({
                  :test_files => args.fetch(:test_files),
                  :build_author => KnapsackPro::RepositoryAdapters::GitAdapter.new.build_author,
                  :commit_authors => KnapsackPro::RepositoryAdapters::GitAdapter.new.commit_authors,
                })
              end

              action_class.new(
                endpoint_path: '/v1/queues/queue',
                http_method: :post,
                request_hash: request_hash
              )
            end
          end
        end
      end
    end
  end
end
