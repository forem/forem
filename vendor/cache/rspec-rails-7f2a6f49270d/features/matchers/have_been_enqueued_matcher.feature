Feature: have_been_enqueued matcher

  The `have_been_enqueued` matcher is used to check if given ActiveJob job was enqueued.

  Background:
    Given active job is available

  Scenario: Checking job class name
    Given a file named "spec/jobs/upload_backups_job_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe UploadBackupsJob do
        it "matches with enqueued job" do
          ActiveJob::Base.queue_adapter = :test
          UploadBackupsJob.perform_later
          expect(UploadBackupsJob).to have_been_enqueued
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
          UploadBackupsJob.perform_later("users-backup.txt", "products-backup.txt")
          expect(UploadBackupsJob).to(
            have_been_enqueued.with("users-backup.txt", "products-backup.txt")
          )
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
          UploadBackupsJob.set(:wait_until => Date.tomorrow.noon).perform_later
          expect(UploadBackupsJob).to have_been_enqueued.at(Date.tomorrow.noon)
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
          UploadBackupsJob.perform_later
          expect(UploadBackupsJob).to have_been_enqueued.at(:no_wait)
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
          UploadBackupsJob.perform_later
          expect(UploadBackupsJob).to have_been_enqueued.on_queue("default")
        end
      end
      """
    When I run `rspec spec/jobs/upload_backups_job_spec.rb`
    Then the examples should all pass
