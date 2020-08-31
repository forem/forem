module Constants
  module Role
    BASE_ROLES = ["Warn",
                  "Comment Ban",
                  "Ban",
                  "Regular Member",
                  "Trusted",
                  "Pro"].freeze

    SPECIAL_ROLES = ["Admin",
                     "Super Admin",
                     "Resource Admin: Article",
                     "Resource Admin: Comment",
                     "Resource Admin: BufferUpdate",
                     "Resource Admin: ChatChannel",
                     "Resource Admin: Page",
                     "Resource Admin: FeedbackMessage",
                     "Resource Admin: Config",
                     "Resource Admin: Broadcast"].freeze
  end
end
