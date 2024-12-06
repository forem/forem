require 'bundler/setup'
require 'rice'
require 'mkmf-rice'
require 'rbconfig'

# Totally hack mkmf to make a unittest executable instead of a shared library
target_exe = "unittest#{RbConfig::CONFIG['EXEEXT']}"
$cleanfiles << target_exe

create_makefile(target_exe) do |conf|
  conf << "\n"
  conf << "#{target_exe}: $(OBJS)"
  conf << "\t$(ECHO) linking executable unittest"
  conf << "\t-$(Q)$(RM) $(@)"

  if IS_MSWIN
    conf << "\t$(Q) $(CXX) -Fe$(@) $(OBJS) $(LIBS) $(LOCAL_LIBS) -link $(ldflags) $(LIBPATH)"
  else
    conf << "\t$(Q) $(CXX) -o $@ $(OBJS) $(LIBPATH) $(LOCAL_LIBS) $(LIBS)"
  end

  conf << "\n"
end
