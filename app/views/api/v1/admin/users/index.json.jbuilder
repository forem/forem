json.users(@users) do |user|
  json.partial!("api/v1/admin/users/user", user: user)
end
json.page @page
json.per_page @per_page
json.total @total
