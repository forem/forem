# This endpoint is for admin-authorized use only. User emails are
# included by design for internal tracking.

json.array! @poll_text_responses do |text_response|
  json.type_of "poll_text_response"
  json.extract!(
    text_response,
    :id,
    :poll_id,
    :user_id,
    :text_content,
    :session_start
  )
  json.user_email text_response.user.email
  json.created_at utc_iso_timestamp(text_response.created_at)
end
