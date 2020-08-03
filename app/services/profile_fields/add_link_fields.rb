module ProfileFields
  class AddLinkFields < AddFields
    field "Facebook profile URL", :text_field, "https://facebook.com/..."
    field "Youtube URL", :text_field, "https://www.youtube.com/channel/..."
    field "StackOverflow profile URL", :text_field, "https://stackoverflow.com/users/..."
    field "LinkedIn profile URL", :text_field, "https://www.linkedin.com/in/..."
    field "Behance profile URL", :text_field, "https://..."
    field "Dribble profile URL", :text_field, "https://dribble.com/..."
    field "Medium profile URL", :text_field, "https://..."
    field "GitLab profile URL", :text_field, "https://..."
    field "Instagram profile URL", :text_field, "https://..."
    field "Mastodon profile URL", :text_field, "https://..."
    field "Twitch profile URL", :text_field, "https://..."
  end
end
