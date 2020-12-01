# This file was generated on 2021-01-02T12:38:45+00:00 from the rspec-dev repo.
# DO NOT modify it by hand as your changes will get lost the next time it is generated.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/ci_functions.sh
source $SCRIPT_DIR/predicate_functions.sh

# If JRUBY_OPTS isn't set, use these.
# see https://docs.travis-ci.com/user/ci-environment/
export JRUBY_OPTS=${JRUBY_OPTS:-"--server -Xcompile.invokedynamic=false"}
SPECS_HAVE_RUN_FILE=specs.out
MAINTENANCE_BRANCH=`cat maintenance-branch`

# Don't allow rubygems to pollute what's loaded. Also, things boot faster
# without the extra load time of rubygems. Only works on MRI Ruby 1.9+
if is_mri_192_plus; then
  export RUBYOPT="--disable=gem"
fi

function clone_repo {
  if [ ! -d $1 ]; then # don't clone if the dir is already there
    if [ -z "$2" ]; then
      BRANCH_TO_CLONE="${MAINTENANCE_BRANCH?}";
    else
      BRANCH_TO_CLONE="$2";
    fi;

    travis_retry eval "git clone https://github.com/rspec/$1 --depth 1 --branch ${BRANCH_TO_CLONE?}"
  fi;
}

function run_specs_and_record_done {
  local rspec_bin=bin/rspec

  # rspec-core needs to run with a special script that loads simplecov first,
  # so that it can instrument rspec-core's code before rspec-core has been loaded.
  if [ -f script/rspec_with_simplecov ] && is_mri; then
    rspec_bin=script/rspec_with_simplecov
  fi;

  echo "${PWD}/bin/rspec"
  $rspec_bin spec --backtrace --format progress --profile --format progress --out $SPECS_HAVE_RUN_FILE
}

function run_cukes {
  if [ -d features ]; then
    # force jRuby to use client mode JVM or a compilation mode thats as close as possible,
    # idea taken from https://github.com/jruby/jruby/wiki/Improving-startup-time
    #
    # Note that we delay setting this until we run the cukes because we've seen
    # spec failures in our spec suite due to problems with this mode.
    export JAVA_OPTS='-client -XX:+TieredCompilation -XX:TieredStopAtLevel=1'

    echo "${PWD}/bin/cucumber"

    if is_mri_192; then
      # For some reason we get SystemStackError on 1.9.2 when using
      # the bin/cucumber approach below. That approach is faster
      # (as it avoids the bundler tax), so we use it on rubies where we can.
      bundle exec cucumber --strict
    elif is_jruby; then
      # For some reason JRuby doesn't like our improved bundler setup
      RUBYOPT="-I${PWD}/../bundle -rbundler/setup" \
         PATH="${PWD}/bin:$PATH" \
         bin/cucumber --strict
    else
      # Prepare RUBYOPT for scenarios that are shelling out to ruby,
      # and PATH for those that are using `rspec` or `rake`.
      RUBYOPT="${RUBYOPT} -I${PWD}/../bundle -rbundler/setup" \
         PATH="${PWD}/bin:$PATH" \
         bin/cucumber --strict
    fi
  fi
}

function run_specs_one_by_one {
  echo "Running each spec file, one-by-one..."

  for file in `find spec -iname '*_spec.rb'`; do
    echo "Running $file"
    bin/rspec $file -b --format progress
  done
}

function run_spec_suite_for {
  if [ ! -f ../$1/$SPECS_HAVE_RUN_FILE ]; then # don't rerun specs that have already run
    if [ -d ../$1 ]; then
      echo "Running specs for $1"
      pushd ../$1
      unset BUNDLE_GEMFILE
      bundle_install_flags=`cat .github/workflows/ci.yml | grep "bundle install" | sed 's/.* bundle install//'`
      travis_retry eval "(unset RUBYOPT; exec bundle install $bundle_install_flags)"
      run_specs_and_record_done
      popd
    else
      echo ""
      echo "WARNING: The ../$1 directory does not exist. Usually the"
      echo "travis build cds into that directory and run the specs to"
      echo "ensure the specs still pass with your latest changes, but"
      echo "we are going to skip that step."
      echo ""
    fi;
  fi;
}

function check_binstubs {
  echo "Checking required binstubs"

  local success=0
  local binstubs=""
  local gems=""

  if [ ! -x ./bin/rspec ]; then
    binstubs="$binstubs bin/rspec"
    gems="$gems rspec-core"
    success=1
  fi

  if [ ! -x ./bin/rake ]; then
    binstubs="$binstubs bin/rake"
    gems="$gems rake"
    success=1
  fi

  if [ -d features ]; then
    if [ ! -x ./bin/cucumber ]; then
      binstubs="$binstubs bin/cucumber"
      gems="$gems cucumber"
      success=1
    fi
  fi

  if [ $success -eq 1 ]; then
    echo
    echo "Missing binstubs:$binstubs"
    echo "Install missing binstubs using one of the following:"
    echo
    echo "  # Create the missing binstubs"
    echo "  $ bundle binstubs$gems"
    echo
    echo "  # To binstub all gems"
    echo "  $ bundle install --binstubs"
    echo
    echo "  # To binstub all gems and avoid loading bundler"
    echo "  $ bundle install --binstubs --standalone"
  fi

  return $success
}

function check_documentation_coverage {
  echo "bin/yard stats --list-undoc"

  bin/yard stats --list-undoc | ruby -e "
    while line = gets
      has_warnings ||= line.start_with?('[warn]:')
      coverage ||= line[/([\d\.]+)% documented/, 1]
      puts line
    end

    unless Float(coverage) == 100
      puts \"\n\nMissing documentation coverage (currently at #{coverage}%)\"
      exit(1)
    end

    if has_warnings
      puts \"\n\nYARD emitted documentation warnings.\"
      exit(1)
    end
  "

  # Some warnings only show up when generating docs, so do that as well.
  bin/yard doc --no-cache | ruby -e "
    while line = gets
      has_warnings ||= line.start_with?('[warn]:')
      has_errors   ||= line.start_with?('[error]:')
      puts line
    end

    if has_warnings || has_errors
      puts \"\n\nYARD emitted documentation warnings or errors.\"
      exit(1)
    end
  "
}

function check_style_and_lint {
  echo "bin/rubocop lib"
  eval "(unset RUBYOPT; exec bin/rubocop lib)"
}

function run_all_spec_suites {
  fold "rspec-core specs" run_spec_suite_for "rspec-core"
  fold "rspec-expectations specs" run_spec_suite_for "rspec-expectations"
  fold "rspec-mocks specs" run_spec_suite_for "rspec-mocks"
  if rspec_rails_compatible; then
    fold "rspec-rails specs" run_spec_suite_for "rspec-rails"
  fi

  if rspec_support_compatible; then
    fold "rspec-support specs" run_spec_suite_for "rspec-support"
  fi
}
