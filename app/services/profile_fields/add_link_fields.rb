module ProfileFields
  class AddLinkFields
    include FieldDefinition

    group "Links" do
      field "Facebook profile URL", :text_field, placeholder: "https://facebook.com/..."
      field "Youtube URL", :text_field, placeholder: "https://www.youtube.com/channel/..."
      field "StackOverflow profile URL", :text_field, placeholder: "https://stackoverflow.com/users/..."
      field "LinkedIn profile URL", :text_field, placeholder: "https://www.linkedin.com/in/..."
      field "Behance profile URL", :text_field, placeholder: "https://..."
      field "Dribble profile URL", :text_field, placeholder: "https://dribble.com/..."
      field "Medium profile URL", :text_field, placeholder: "https://..."
      field "GitLab profile URL", :text_field, placeholder: "https://..."
      field "Instagram profile URL", :text_field, placeholder: "https://..."
      field "Mastodon profile URL", :text_field, placeholder: "https://..."
      field "Twitch profile URL", :text_field, placeholder: "https://..."
    end
  end
end
