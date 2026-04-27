require_relative 'config/environment'
a = Article.last
a.update_columns(score: 0)
a.score = 10
puts "score_changed? #{a.score_changed?}"
a.update_columns(score: 10)
puts "score_changed? after update_columns #{a.score_changed?}"
a.score = 10
puts "score_changed? after setting to 10 again #{a.score_changed?}"
