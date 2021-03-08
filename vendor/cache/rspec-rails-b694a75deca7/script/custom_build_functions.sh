function run_cukes {
  if is_mri; then
    bin/rake acceptance --trace
    return $?
  elif is_jruby; then
    bin/rake smoke:app
    return $?
  else
    return 0
  fi
}

# rspec-rails depends on all of the other rspec repos. Conversely, none of the
# other repos have any dependencies with rspec-rails directly. If the other
# repos have issues, the rspec-rails suite and cukes would fail exposing them.
# Since we are already implicitly testing them we do not need to run their spec
# suites explicitly.
function run_all_spec_suites {
  fold "one-by-one specs" run_specs_one_by_one
}
