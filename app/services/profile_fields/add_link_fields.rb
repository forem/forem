module ProfileFields
  class AddLinkFields
    include FieldDefinition

    group "Links" do
      field "Facebook URL", :text_field, placeholder: "https://facebook.com/...", display_area: "header"
      field "Youtube URL", :text_field, placeholder: "https://www.youtube.com/channel/...", display_area: "header"
      field "StackOverflow URL", :text_field, placeholder: "https://stackoverflow.com/users/...", display_area: "header"
      field "LinkedIn URL", :text_field, placeholder: "https://www.linkedin.com/in/...", display_area: "header"
      field "Behance URL", :text_field, placeholder: "https://www.behance.net/...", display_area: "header"
      field "Dribbble URL", :text_field, placeholder: "https://dribbble.com/...", display_area: "header"
      field "Medium URL", :text_field, placeholder: "https://medium.com/@...", display_area: "header"
      field "GitLab URL", :text_field, placeholder: "https://gitlab.com/...", display_area: "header"
      field "Instagram URL", :text_field, placeholder: "https://www.instagram.com/...", display_area: "header"
      field "Mastodon URL", :text_field, placeholder: "https://...", display_area: "header"
      field "Twitch URL", :text_field, placeholder: "https://www.twitch.tv/...", display_area: "header"
    end
  end
end
