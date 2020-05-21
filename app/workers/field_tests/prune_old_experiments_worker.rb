module FieldTests
  class PruneOldExperimentsWorker
    include Sidekiq::Worker
    sidekiq_options queue: :low_priority, retry: 10

    def perform
      five_precent_membership_count = FieldTest::Membership.count / 20
      memberships = FieldTest::Membership.first(five_precent_membership_count)
      FieldTest::Event.where(field_test_membership_id: memberships.pluck(:id)).delete_all
      memberships.map(&:delete)
    end
  end
end
