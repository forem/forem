# NOTE: we can remove this once the DUS using it finished
class MigrateDataToWorkFieldWorker
  include Sidekiq::Worker

  def perform(profile_id)
    profile = Profile.find_by(id: profile_id)
    return unless profile

    work_info = profile.employment_title
    work_info << " at #{profile.employer_name}" if profile.employer_name.present?
    profile.update(work: work_info)
  end
end
