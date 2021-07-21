json.extract!(
  @user.profile,
  :summary, :employment_title, :employer_name, :employer_url, :location, :education
)

json.email @user.email if @user.setting.display_email_on_profile

json.created_at utc_iso_timestamp(@user.created_at)
