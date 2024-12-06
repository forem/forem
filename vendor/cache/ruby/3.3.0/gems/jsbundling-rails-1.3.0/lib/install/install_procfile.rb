if Rails.root.join("Procfile.dev").exist?
  append_to_file "Procfile.dev", "js: yarn build --watch\n"
else
  say "Add default Procfile.dev"
  copy_file "#{__dir__}/Procfile.dev", "Procfile.dev"

  say "Ensure foreman is installed"
  run "gem install foreman"
end
