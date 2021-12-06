SHA = "393d678718de02a15ba8c4894529c9494151211f"
app_dirs = `ls #{ENV['HOME']}/git/forem/app`.split("\n")
count = 0
app_dirs.each do |dir|
  results = []
  regexps = [
    '\.(?:hotness_)?score[^_]',
    'score [><]'
  ].each do |regexp|
    output = `cd #{ENV['HOME']}/git/forem;  rg "#{regexp}" app/#{dir} --line-number | awk -F": *" '{ print "- [ ] [" $1 ":" $2 "](https://github.com/forem/forem/blob/#{SHA}/" $1 "#L" $2 ") has \`" $3 "\`"}'`.split("\n")
    results += output if output.size > 0
  end

  next if results.size.zero?
  puts "### app/#{dir}\n\n"
  puts results.join("\n")
  count += results.size
  puts "\n\n"
end

puts "There are #{count} places to check"
