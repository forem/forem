json.default_nav_links do
  json.array! @navigation_links[:default_nav_links],
              partial: "navigation_link",
              as: :navigation_link,
              cached: true
end

json.other_nav_links do
  json.array! @navigation_links[:other_nav_links],
              partial: "navigation_link",
              as: :navigation_link,
              cached: true
end
