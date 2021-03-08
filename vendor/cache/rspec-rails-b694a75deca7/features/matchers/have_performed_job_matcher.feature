Feature: have_performed_job matcher

  The `have_performed_job` (also aliased as `perform_job`) matcher is used to check if given ActiveJob job was performed.

  Background:
    Given active job is available

  Scenario: Checking job class name
    Given a file named "spec/jobs/upload_backups_job_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe UploadBackupsJob do
        it "matches with performed job" do
          ActiveJob::Base.queue_adapter = :test
          ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
          expect {
            UploadBackupsJob.perform_later
          }.to have_performed_job(UploadBackupsJob)
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
        it "matches with performed job" do
          ActiveJob::Base.queue_adapter = :test
          ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
          expect {
            UploadBackupsJob.perform_later("users-backup.txt", "products-backup.txt")
          }.to have_performed_job.with("users-backup.txt", "products-backup.txt")
        end
      end
      """
    When I run `rspec spec/jobs/upload_backups_job_spec.rb`
    Then the examples should all pass

  Scenario: Checking job performed time
    Given a file named "spec/jobs/upload_backups_job_spec.rb" with:
      """ruby
      require "rails_helper"

      RSpec.describe UploadBackupsJob do
        it "matches with performed job" do
          ActiveJob::Base.queue_adapter = :test
          ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
          ActiveJob::Base.queue_adapter.perform_enqueued_at_jobs = true
          expect {
            UploadBackupsJob.set(:wait_until => Date.tomorrow.noon).perform_later
          }.to have_performed_job.at(Date.tomorrow.noon)
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
        it "matches with performed job" do
          ActiveJob::Base.queue_adapter = :test
          ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
          expect {
            UploadBackupsJob.perform_later
          }.to have_performed_job.on_queue("default")
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
        it "matches with performed job" do
          ActiveJob::Base.queue_adapter = :test
          ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
          expect {
            UploadBackupsJob.perform_later
          }.to perform_job(UploadBackupsJob)
        end
      end
      """
    When I run `rspec spec/jobs/upload_backups_job_spec.rb`
    Then the examples should all pass
