# This file was generated on 2019-12-18T14:01:39+00:00 from the rspec-dev repo.
# DO NOT modify it by hand as your changes will get lost the next time it is generated.

function is_mri {
  if ruby -e "exit(!defined?(RUBY_ENGINE) || RUBY_ENGINE == 'ruby')"; then
    # RUBY_ENGINE only returns 'ruby' on MRI.
    # MRI 1.8.7 lacks the constant but all other rubies have it (including JRuby in 1.8 mode)
    return 0
  else
    return 1
  fi;
}

function is_jruby {
  if ruby -e "exit(defined?(RUBY_PLATFORM) && RUBY_PLATFORM == 'java')"; then
    # RUBY_ENGINE only returns 'ruby' on MRI.
    # MRI 1.8.7 lacks the constant but all other rubies have it (including JRuby in 1.8 mode)
    return 0
  else
    return 1
  fi;
}

function is_mri_192 {
  if is_mri; then
    if ruby -e "exit(RUBY_VERSION == '1.9.2')"; then
      return 0
    else
      return 1
    fi
  else
    return 1
  fi
}

function is_mri_192_plus {
  if is_mri; then
    if ruby -e "exit(RUBY_VERSION.to_f > 1.8)"; then
      return 0
    else
      return 1
    fi
  else
    return 1
  fi
}

function is_mri_2plus {
  if is_mri; then
    if ruby -e "exit(RUBY_VERSION.to_f > 2.0)"; then
      return 0
    else
      return 1
    fi
  else
    return 1
  fi
}

function is_ruby_23_plus {
  if ruby -e "exit(RUBY_VERSION.to_f >= 2.3)"; then
    return 0
  else
    return 1
  fi
}

function rspec_rails_compatible {
  if is_ruby_23_plus; then
    return 0
  else
    return 1
  fi
}

function rspec_support_compatible {
  if [ "$MAINTENANCE_BRANCH" != "2-99-maintenance" ] && [ "$MAINTENANCE_BRANCH" != "2-14-maintenance" ]; then
    return 0
  else
    return 1
  fi
}

function additional_specs_available {
  type run_additional_specs > /dev/null 2>&1
  return $?
}

function documentation_enforced {
  if [ -x ./bin/yard ]; then
    if is_mri_2plus; then
      return 0
    else
      return 1
    fi
  else
    return 1
  fi
}

function style_and_lint_enforced {
 if [ -x ./bin/rubocop ]; then
   return 0
 else
   return 1
 fi
}
