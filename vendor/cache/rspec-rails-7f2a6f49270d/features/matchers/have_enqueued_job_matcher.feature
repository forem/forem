Feature: have_enqueued_job matcher

  The `have_enqueued_job` (also aliased as `enqueue_job`) matcher is used to check if given ActiveJob job was enqueued.

  Background:
    Given active job is available

  Scenario: Checking job class name
    Given a file named "spec/jobs/upload_backups_job_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe UploadBackupsJob do
        it "matches with enqueued job" do
          ActiveJob::Base.queue_adapter = :test
          expect {
            UploadBackupsJob.perform_later
          }.to have_enqueued_job(UploadBackupsJob)
        end
      end
      """
    When I run `rspec spec/jobs/upload_backups_job_spec.rb`
    Then the examples should all pass

  Scenario: Checking passed arguments to job
    Given a file named "spec/jobs/upload_backups_job_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe UploadBackupsJob do
        it "matches with enqueued job" do
          ActiveJob::Base.queue_adapter = :test
          expect {
            UploadBackupsJob.perform_later("users-backup.txt", "products-backup.txt")
          }.to have_enqueued_job.with("users-backup.txt", "products-backup.txt")
        end
      end
      """
    When I run `rspec spec/jobs/upload_backups_job_spec.rb`
    Then the examples should all pass

  Scenario: Checking passed arguments to job, using a block
    Given a file named "spec/jobs/upload_backups_job_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe UploadBackupsJob do
        it "matches with enqueued job" do
          ActiveJob::Base.queue_adapter = :test
          expect {
            UploadBackupsJob.perform_later('backups.txt', rand(100), 'uninteresting third argument')
          }.to have_enqueued_job.with { |file_name, seed|
            expect(file_name).to eq 'backups.txt'
            expect(seed).to be < 100
          }
        end
      end
      """
    When I run `rspec spec/jobs/upload_backups_job_spec.rb`
    Then the examples should all pass

  Scenario: Checking job enqueued time
    Given a file named "spec/jobs/upload_backups_job_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe UploadBackupsJob do
        it "matches with enqueued job" do
          ActiveJob::Base.queue_adapter = :test
          expect {
            UploadBackupsJob.set(:wait_until => Date.tomorrow.noon).perform_later
          }.to have_enqueued_job.at(Date.tomorrow.noon)
        end
      end
      """
    When I run `rspec spec/jobs/upload_backups_job_spec.rb`
    Then the examples should all pass

  Scenario: Checking job enqueued with no wait
    Given a file named "spec/jobs/upload_backups_job_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe UploadBackupsJob do
        it "matches with enqueued job" do
          ActiveJob::Base.queue_adapter = :test
          expect {
            UploadBackupsJob.perform_later
          }.to have_enqueued_job.at(:no_wait)
        end
      end
      """
    When I run `rspec spec/jobs/upload_backups_job_spec.rb`
    Then the examples should all pass

  Scenario: Checking job queue name
    Given a file named "spec/jobs/upload_backups_job_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe UploadBackupsJob do
        it "matches with enqueued job" do
          ActiveJob::Base.queue_adapter = :test
          expect {
            UploadBackupsJob.perform_later
          }.to have_enqueued_job.on_queue("default")
        end
      end
      """
    When I run `rspec spec/jobs/upload_backups_job_spec.rb`
    Then the examples should all pass

  Scenario: Using alias method
    Given a file named "spec/jobs/upload_backups_job_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe UploadBackupsJob do
        it "matches with enqueued job" do
          ActiveJob::Base.queue_adapter = :test
          expect {
            UploadBackupsJob.perform_later
          }.to enqueue_job(UploadBackupsJob)
        end
      end
      """
    When I run `rspec spec/jobs/upload_backups_job_spec.rb`
    Then the examples should all pass
