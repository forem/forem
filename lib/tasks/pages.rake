namespace :pages do
  desc "binds a Page using it's slug to local HTML file (absolute path)"
  task :bind, [:slug, :filepath] => [:environment] do |task, args|
    listener = Listen.to(Pathname.new(args.filepath).dirname) do
      puts "Reloading page..."
      page = Page.find_by(slug: args.slug)
      page.body_html = File.read(args.filepath)
      puts "Error updating page: #{page.errors.messages}" unless page.save
    end

    listener.start # not blocking
    puts "Happy Coding!"
    begin
      sleep
    rescue Exception => e
      puts "\nBye :)"
    end
  end
end
