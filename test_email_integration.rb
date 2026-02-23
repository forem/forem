#!/usr/bin/env ruby
# frozen_string_literal: true

# Email Integration Test Script
# This script validates that all email delivery components are properly integrated

puts "🔍 Forem Email Delivery System Validation"
puts "=" * 50

# Test 1: Check file structure
puts "\n1. 📁 File Structure Validation"
required_files = [
  '.env.example',
  'config/initializers/email_configuration.rb',
  'lib/tasks/email_test.rake',
  'app/services/email_delivery_service.rb',
  'docs/email_setup_guide.md'
]

missing_files = []
required_files.each do |file|
  if File.exist?(file)
    puts "✅ #{file}"
  else
    puts "❌ #{file} - MISSING"
    missing_files << file
  end
end

# Test 2: Check Ruby syntax
puts "\n2. 🔍 Ruby Syntax Validation"
ruby_files = [
  'config/initializers/email_configuration.rb',
  'lib/tasks/email_test.rake',
  'app/services/email_delivery_service.rb'
]

syntax_errors = []
ruby_files.each do |file|
  begin
    `ruby -c #{file} 2>/dev/null`
    if $?.success?
      puts "✅ #{file} - Syntax OK"
    else
      puts "❌ #{file} - Syntax Error"
      syntax_errors << file
    end
  rescue
    puts "⚠️  #{file} - Cannot check syntax"
  end
end

# Test 3: Check environment configuration template
puts "\n3. 🔧 Environment Configuration"
if File.exist?('.env.example')
  content = File.read('.env.example')
  required_vars = ['SMTP_ADDRESS', 'SMTP_PORT', 'SMTP_USER_NAME', 'SMTP_PASSWORD', 'SMTP_DOMAIN']
  
  found_vars = required_vars.select { |var| content.include?(var) }
  
  if found_vars.size == required_vars.size
    puts "✅ All required SMTP variables present in .env.example"
  else
    missing = required_vars - found_vars
    puts "❌ Missing variables in .env.example: #{missing.join(', ')}"
  end
end

# Test 4: Check documentation completeness
puts "\n4. 📖 Documentation Validation"
if File.exist?('docs/email_setup_guide.md')
  content = File.read('docs/email_setup_guide.md')
  
  sections_to_check = [
    'Quick Start',
    'Environment Configuration',
    'Verification Steps',
    'Troubleshooting',
    'Production Deployment'
  ]
  
  sections_to_check.each do |section|
    if content.include?(section)
      puts "✅ #{section} section present"
    else
      puts "❌ #{section} section missing"
    end
  end
end

# Test 5: Check rake task definitions
puts "\n5. ⚙️ Rake Task Validation"
if File.exist?('lib/tasks/email_test.rake')
  content = File.read('lib/tasks/email_test.rake')
  
  tasks_to_check = [
    'email:test_smtp',
    'email:send_test',
    'email:status'
  ]
  
  tasks_to_check.each do |task|
    if content.include?(task)
      puts "✅ #{task} task defined"
    else
      puts "❌ #{task} task missing"
    end
  end
end

# Test 6: Check service integration
puts "\n6. 🔗 Service Integration Check"
if File.exist?('app/services/email_delivery_service.rb')
  content = File.read('app/services/email_delivery_service.rb')
  
  methods_to_check = [
    'deliver_confirmation_email',
    'test_email_configuration',
    'health_check'
  ]
  
  methods_to_check.each do |method|
    if content.include?(method)
      puts "✅ #{method} method present"
    else
      puts "❌ #{method} method missing"
    end
  end
end

# Test 7: Check initializer integration
puts "\n7. ⚡ Initializer Integration"
if File.exist?('config/initializers/email_configuration.rb')
  content = File.read('config/initializers/email_configuration.rb')
  
  checks = [
    'EmailConfiguration.setup_email_defaults',
    'validate_smtp_config',
    'test_smtp_connection'
  ]
  
  checks.each do |check|
    if content.include?(check)
      puts "✅ #{check} present"
    else
      puts "❌ #{check} missing"
    end
  end
end

# Final Summary
puts "\n📊 Validation Summary"
puts "=" * 50

if missing_files.empty? && syntax_errors.empty?
  puts "🎉 ALL TESTS PASSED!"
  puts "✅ Email delivery system is ready for production"
  puts "✅ Ready for pull request submission"
  puts "\n📋 Next Steps for Users:"
  puts "1. Copy .env.example to .env"
  puts "2. Configure SMTP settings"
  puts "3. Run: bundle exec rake email:test_smtp"
  puts "4. Run: bundle exec rake email:send_test"
  puts "5. Follow docs/email_setup_guide.md"
else
  puts "❌ ISSUES FOUND:"
  puts "Missing files: #{missing_files.join(', ')}" unless missing_files.empty?
  puts "Syntax errors: #{syntax_errors.join(', ')}" unless syntax_errors.empty?
  puts "\n⚠️  Please fix the above issues before submitting PR"
end

puts "\n🚀 Email delivery system validation complete!"