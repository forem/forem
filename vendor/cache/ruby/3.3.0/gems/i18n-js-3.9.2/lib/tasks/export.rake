namespace :i18n do
  namespace :js do
    desc "Export translations to JS file(s)"
    task :export => :environment do
      I18n::JS.export
    end
  end
end
