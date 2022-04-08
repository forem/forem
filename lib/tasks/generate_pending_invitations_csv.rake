class GeneratePendingInvitationsCsv
  include Rake::DSL
  include Rails.application.routes.url_helpers

  def initialize
    namespace :prospera do
      desc "Generate Pending Invitations CSV"
      task generate_pending_invitations_csv: :environment do
        puts "email, invitation_url"
        User.invitation_not_accepted.find_each do |user|
          user.invite! { |invite| invite.skip_invitation = true }
          invitation_url = accept_user_invitation_url(
            invitation_token: user.raw_invitation_token,
          )
          user.touch(:invitation_sent_at)

          puts "#{user.email}, #{invitation_url}"
        end
      end
    end
  end
end

GeneratePendingInvitationsCsv.new
