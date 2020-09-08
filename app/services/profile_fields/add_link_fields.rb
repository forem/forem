module ProfileFields
  class AddLinkFields
    include FieldDefinition

    group "Links" do
      field "Facebook URL", :text_field, placeholder: "https://facebook.com/..."
      field "Youtube URL", :text_field, placeholder: "https://www.youtube.com/channel/..."
      field "StackOverflow URL", :text_field, placeholder: "https://stackoverflow.com/users/..."
      field "LinkedIn URL", :text_field, placeholder: "https://www.linkedin.com/in/..."
      field "Behance URL", :text_field, placeholder: "https://www.behance.net/..."
      field "Dribbble URL", :text_field, placeholder: "https://dribbble.com/..."
      field "Medium URL", :text_field, placeholder: "https://medium.com/@..."
      field "GitLab URL", :text_field, placeholder: "https://gitlab.com/..."
      field "Instagram URL", :text_field, placeholder: "https://www.instagram.com/..."
      field "Mastodon URL", :text_field, placeholder: "https://..."
      field "Twitch URL", :text_field, placeholder: "https://www.twitch.tv/..."
    end
  end
end
