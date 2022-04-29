module DataUpdateScripts
  class RemoveMailchimpSustainingMembersNewsletter
    def run
      Settings::General.where(var: "mailchimp_sustaining_members_id").destroy_all
    end
  end
end
