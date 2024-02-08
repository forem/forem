json.partial! "api/v1/shared/user_show_extended", user: @user
json.followers_count @user.good_standing_followers_count
