json.type_of            "user"
json.id                 @user.id
json.username           @user.username
json.name               @user.name
json.summary            @user.summary
json.twitter_username   @user.twitter_username
json.github_username    @user.github_username
json.website_url        @user.website_url
json.location           @user.location
json.joined_at          @user.created_at.strftime("%b %e, %Y")
json.profile_image      ProfileImage.new(@user).get(width: 320)
