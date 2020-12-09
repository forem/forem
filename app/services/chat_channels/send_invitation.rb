module ChatChannels
  class SendInvitation
    attr_accessor :invitation_usernames, :current_user, :chat_channel

    def initialize(invitation_usernames, current_user, chat_channel)
      @invitation_usernames = invitation_usernames
      @current_user = current_user
      @chat_channel = chat_channel
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      if invitation_usernames.present?
        usernames = invitation_usernames.split(",").map do |username|
          username.strip.delete("@")
        end
        users = User.where(username: usernames)
        invitations_sent = chat_channel.invite_users(users: users, membership_role: "member", inviter: current_user)
        message = if invitations_sent.zero?
                    "No invitations sent. Check for username typos."
                  else
                    "#{invitations_sent} #{'invitation'.pluralize(invitations_sent)} sent."
                  end
      end
      message
    end
  end
end
