# Helpers for Sidekiq tests
# modeled after <https://api.rubyonrails.org/v5.2/classes/ActiveJob/TestHelper.html>
module SidekiqTestHelpers
  # Asserts that the job passed in the block has been enqueued with the given arguments.
  # check <https://api.rubyonrails.org/v5.2/classes/ActiveJob/TestHelper.html#method-i-assert_enqueued_with>
  # for examples
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

  class Utils
    def self.prepare_args(args)
      args.dup.tap do |arguments|
        arguments[:at] = arguments[:at].to_f if arguments[:at]
        arguments[:class] = arguments[:job].to_s
        arguments.delete(:job)
      end.with_indifferent_access
    end
  end
end
