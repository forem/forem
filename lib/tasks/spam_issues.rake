# frozen_string_literal: true

namespace :spam_issues do
  desc "Close obvious spam issues (add --dry-run flag to preview)"
  task close_obvious: :environment do
    dry_run = ENV["DRY_RUN"] != "false" && ARGV.include?("--dry-run")
    
    puts "Closing obvious spam issues (dry_run: #{dry_run})"
    puts "Use DRY_RUN=false to actually close issues" if dry_run
    
    result = SpamIssues::CloseObviousSpam.call(dry_run: dry_run)
    
    if result[:issues].any?
      puts "\nFound #{result[:issues].length} obvious spam issue(s):"
      result[:issues].each do |issue|
        puts "  ##{issue[:number]}: #{issue[:title]} by #{issue[:author]}"
        puts "    URL: #{issue[:url]}"
      end
      
      if dry_run
        puts "\nRun with DRY_RUN=false to close these issues"
      else
        puts "\nClosed #{result[:closed]} issue(s)"
      end
    else
      puts "No obvious spam issues found"
    end
  end
end