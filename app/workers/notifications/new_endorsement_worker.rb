# module Notifications
#   class NewEndorsementWorker
#     include Sidekiq::Worker

#     sidekiq_options queue: :medium_priority, retry: 10

#     def perform(listing_endorsement, is_approved = false)
#       Notifications::NewEndorsement::Send.call(listing_endorsement, is_approved)
#     end
#   end
# end
