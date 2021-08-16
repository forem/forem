json.extract!(
  @user.profile,
  :summary, :location
)

json.card_color(
  Color::CompareHex.new([user_colors(@user)[:bg], user_colors(@user)[:text]]).brightness(0.88),
)

json.email @user.email if @user.setting.display_email_on_profile

json.created_at utc_iso_timestamp(@user.created_at)

# Dynamically add the information for the header fields (maximum of 3 fields)
header_fields = @user.profile.decorate.ui_attributes_for(area: :header)
header_fields.each do |title, value|
  json.set! title, value
end
