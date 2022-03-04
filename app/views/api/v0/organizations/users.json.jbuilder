json.array! @users do |user|
  json.partial! "api/v0/shared/user_show", user: user
end
