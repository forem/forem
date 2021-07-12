# NOTE: this worker is only used inside a DUS. Once that ran across the fleet
# and we gave self-hosters some time to run it to we should be able to remove
# this.
class MigrateDataToWorkFieldWorker
  include Sidekiq::Worker

  def perform(profile_id)
    profile = Profile.find_by(id: profile_id)
    return unless profile

    work_info = profile.employment_title
    work_info << " at #{profile.employer_name}" if profile.employer_name.present?

    # NOTE: This worker is only concerned with updating "work", an unvalidated
    # key in the JSONB data object. We don't want this to fail, even if e.g.
    # a newly added validation makes the record invalid.
    profile.data[:work] = work_info
    profile.save(validate: false)
  end
end
