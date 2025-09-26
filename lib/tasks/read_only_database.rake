namespace :read_only_database do
  desc "Check read-only database connection health"
  task health_check: :environment do
    puts "Checking read-only database connection..."

    health = ReadOnlyDatabaseService.health_check
    puts "Status: #{health[:status]}"
    puts "Message: #{health[:message]}"

    if ReadOnlyDatabaseService.available?
      info = ReadOnlyDatabaseService.connection_info
      puts "Connection Info:"
      puts "  Host: #{info[:host]}"
      puts "  Port: #{info[:port]}"
      puts "  Database: #{info[:database]}"
      puts "  Username: #{info[:username]}"
    end

    exit(1) if health[:status] == "unhealthy"
  end

  desc "Test read-only database with a simple query"
  task test_query: :environment do
    puts "Testing read-only database with a simple query..."

    begin
      ReadOnlyDatabaseService.with_connection do |conn|
        result = conn.execute("SELECT COUNT(*) as user_count FROM users")
        count = result.first["user_count"]
        puts "✅ Successfully connected to read-only database"
        puts "   User count: #{count}"
      end
    rescue StandardError => e
      puts "❌ Failed to execute query on read-only database: #{e.message}"
      exit(1)
    end
  end

  desc "Reset read-only database connection pool"
  task reset_pool: :environment do
    puts "Resetting read-only database connection pool..."
    ReadOnlyDatabaseService.reset_connection_pool!
    puts "✅ Connection pool reset successfully"
  end
end
