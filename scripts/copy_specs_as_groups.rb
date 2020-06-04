require 'fileutils'

groups = [[
  'spec/system/articles/user_edits_an_article_spec.rb',
  'spec/system/articles/user_visits_article_stats_spec.rb'
], [
  'spec/system/internal/admin_awards_badges_spec.rb',
  'spec/system/internal/admin_bans_or_warns_user_spec.rb'
],[
  'spec/system/internal/admin_deletes_user_spec.rb',
  'spec/system/internal/admin_manages_organizations_spec.rb'
],[
  'spec/system/internal/admin_manages_reports_spec.rb',
  'spec/system/notifications/notifications_page_spec.rb'
]]

groups_dir = File.join(Dir.pwd, 'spec/system/groups')
FileUtils.mkdir_p(groups_dir)

num_copies = 5
total = 0
groups.each do |group|
  first_spec = File.join(Dir.pwd, group[0])
  second_spec = File.join(Dir.pwd, group[1])
  num_copies.times do
    FileUtils.cp(first_spec, File.join(groups_dir, "#{total}_spec.rb"))
    total += 1
    FileUtils.cp(second_spec, File.join(groups_dir, "#{total}_spec.rb"))
    total += 1
  end
end
