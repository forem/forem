require 'fileutils'

groups = [[
  'spec/system/internal/admin_awards_badges_spec.rb',
  'spec/system/internal/admin_bans_or_warns_user_spec.rb'
]]

groups_dir = File.join(Dir.pwd, 'spec/system/groups')
FileUtils.mkdir_p(groups_dir)

num_copies = 50
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
