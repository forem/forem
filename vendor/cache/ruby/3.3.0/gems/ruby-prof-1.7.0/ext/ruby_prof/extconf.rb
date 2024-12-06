require "mkmf"

# Let's go with a modern version of C! want to intermix declarations and code (ie, don't define
# all variables at the top of the method). If using Visual Studio, you'll need 2019 version
# 16.8 or higher
if RUBY_PLATFORM =~ /mswin/
  $CFLAGS += ' /std:c11'
else
  $CFLAGS += ' -std=c11'
end

# For gcc add -s to strip symbols, reducing library size from 17MB to 78KB (at least on Windows with mingw64)
if RUBY_PLATFORM !~ /mswin/
  $LDFLAGS += ' -s'
end

# And since we are using C99 we want to disable Ruby sending these warnings to gcc
if CONFIG['warnflags']
  CONFIG['warnflags'].gsub!('-Wdeclaration-after-statement', '')
end

create_makefile("ruby_prof")
