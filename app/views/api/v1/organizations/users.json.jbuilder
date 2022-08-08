json.array! @users do |user|
  json.partial! "api/v1/shared/user_show", user: user
end
