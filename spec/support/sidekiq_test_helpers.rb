# Helpers for Sidekiq tests
# modeled after <https://api.rubyonrails.org/v5.2/classes/ActiveJob/TestHelper.html>
# NOTE: contains code adapted from <https://github.com/rails/rails/blob/ac30e389ecfa0e26e3d44c1eda8488ddf63b3ecc/activejob/lib/active_job/test_helper.rb>
# and from <https://github.com/mperham/sidekiq/blob/ee65b5365e0c810c9defc5f1e269d53e971d783c/lib/sidekiq/testing.rb>
module SidekiqTestHelpers
  # Provides a store of all the enqueued jobs
  def sidekiq_enqueued_jobs(queue: nil, worker: nil)
    raise ArgumentError, "Cannot specify both `:queue` and `:worker` options." if queue && worker

    return Sidekiq::Queues.jobs_by_queue[queue.to_s] if queue
    return Sidekiq::Queues.jobs_by_worker[worker.to_s] if worker

    Sidekiq::Worker.jobs
  end

  # Asserts that the number of enqueued jobs matches the given number.
  # see <https://api.rubyonrails.org/v5.2/classes/ActiveJob/TestHelper.html#method-i-assert_enqueued_jobs>
  def sidekiq_assert_enqueued_jobs(number, only: nil, except: nil, queue: nil)
    if block_given?
      original_count = Utils.enqueued_jobs_size(only: only, except: except, queue: queue)

      yield
      new_count = Utils.enqueued_jobs_size(only: only, except: except, queue: queue)

      error_message = "#{number} jobs expected, but #{new_count - original_count} were enqueued"
      expect(new_count - original_count).to eq(number), error_message
    else
      actual_count = Utils.enqueued_jobs_size(only: only, except: except, queue: queue)

      expect(actual_count).to eq(number), "#{number} jobs expected, but #{actual_count} were enqueued"
    end
  end

  # Asserts that the job passed in the block has been enqueued with the given arguments.
  # see <https://api.rubyonrails.org/v5.2/classes/ActiveJob/TestHelper.html#method-i-assert_enqueued_with>
  def sidekiq_assert_enqueued_with(job: nil, args: nil, at: nil, queue: nil)
    expected = { job: job, args: args, at: at, queue: queue }.compact
    expected_args = Utils.prepare_args(expected)

    yield

    # check there's at least one job with the given args
    matching_job = job.jobs.detect do |queued_job|
      expected_args.all? { |key, value| value == queued_job[key] }
    end

    expect(matching_job).to be_present, "No enqueued job found with #{expected}"
  end

  def sidekiq_assert_not_enqueued_with(job: nil, args: nil, at: nil, queue: nil)
    expected = { job: job, args: args, at: at, queue: queue }.compact
    expected_args = Utils.prepare_args(expected)

    yield

    # check there's at least one job with the given args
    matching_job = job.jobs.detect do |queued_job|
      expected_args.all? { |key, value| value == queued_job[key] }
    end

    expect(matching_job).not_to be_present, "Job unexpectedly found with #{expected}"
  end

  # Asserts that no jobs have been enqueued.
  # see <https://api.rubyonrails.org/v5.2/classes/ActiveJob/TestHelper.html#method-i-assert_no_enqueued_jobs>
  def sidekiq_assert_no_enqueued_jobs(only: nil, except: nil, &block)
    sidekiq_assert_enqueued_jobs(0, only: only, except: except, &block)
  end

  # Performs all enqueued jobs.
  # If a block is given, performs all of the jobs that were enqueued throughout the duration of the block.
  # If a block is not given, performs all of the enqueued jobs up to this point in the test.
  # see <https://api.rubyonrails.org/classes/ActiveJob/TestHelper.html#method-i-perform_enqueued_jobs>
  def sidekiq_perform_enqueued_jobs(only: nil, except: nil)
    Utils.validate_option(only: only, except: except)

    if block_given?
      jobs_enqueued_before_block = sidekiq_enqueued_jobs

      yield

      jobs_to_perform = sidekiq_enqueued_jobs - jobs_enqueued_before_block

      Utils.drain_jobs(jobs_to_perform, only: only, except: except)
    else
      Utils.drain_jobs(sidekiq_enqueued_jobs, only: only, except: except)
    end
  end

  # Perform all Sidekiq jobs until there are no longer any in the queues
  def drain_all_sidekiq_jobs
    sidekiq_perform_enqueued_jobs while Sidekiq::Worker.jobs.any?
  end

  class Utils
    class << self
      def drain_jobs(jobs, only: nil, except: nil)
        jobs_to_perform = jobs
        jobs_to_perform = jobs_to_perform.filter { |j| j["class"] == only.to_s } if only
        jobs_to_perform = jobs_to_perform.reject { |j| j["class"] == except.to_s } if except

        jobs_to_perform.each do |job|
          Sidekiq::Queues.delete_for(job["jid"], job["queue"], job["class"])
          job["class"].constantize.process_job(job)
        end
      end

      def enqueued_jobs_size(only: nil, except: nil, queue: nil)
        validate_option(only: only, except: except)

        Sidekiq::Worker.jobs.count do |job|
          job_class = job.fetch("class")
          if only
            next false unless Array(only).include?(job_class.constantize)
          elsif except
            next false if Array(except).include?(job_class.constantize)
          end
          if queue
            next false unless queue.to_s == job.fetch("queue") # rubocop:disable Style/SoleNestedConditional
          end
          true
        end
      end

      def validate_option(only: nil, except: nil)
        raise ArgumentError, "Cannot specify both `:only` and `:except` options." if only && except
      end

      def prepare_args(args)
        args.dup.tap do |arguments|
          arguments[:at] = arguments[:at].to_f if arguments[:at]
          arguments[:class] = arguments[:job].to_s
          arguments.delete(:job)
        end.with_indifferent_access
      end
    end
  end
end
