json.array! @poll_votes do |vote|
  json.type_of "poll_vote"
  json.extract!(
    vote,
    :id,
    :poll_id,
    :poll_option_id,
    :user_id,
    :session_start
  )
  json.username vote.user.username
  json.created_at utc_iso_timestamp(vote.created_at)
end
