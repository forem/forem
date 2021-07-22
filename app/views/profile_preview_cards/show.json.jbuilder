json.extract!(
  @user.profile,
  :summary, :location, :education, :work
)

json.card_color(
  Color::CompareHex.new([user_colors(@user)[:bg], user_colors(@user)[:text]]).brightness(0.88),
)

json.email @user.email if @user.setting.display_email_on_profile

json.created_at utc_iso_timestamp(@user.created_at)
