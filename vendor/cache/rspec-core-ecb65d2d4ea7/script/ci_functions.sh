# This file was generated on 2021-01-22T18:13:35+00:00 from the rspec-dev repo.
# DO NOT modify it by hand as your changes will get lost the next time it is generated.

# Taken from:
# https://github.com/travis-ci/travis-build/blob/e9314616e182a23e6a280199cd9070bfc7cae548/lib/travis/build/script/templates/header.sh#L34-L53
travis_retry() {
  local result=0
  local count=1
  while [ $count -le 3 ]; do
    [ $result -ne 0 ] && {
      echo -e "\n\033[33;1mThe command \"$@\" failed. Retrying, $count of 3.\033[0m\n" >&2
    }
    "$@"
    result=$?
    [ $result -eq 0 ] && break
    count=$(($count + 1))
    sleep 1
  done

  [ $count -eq 3 ] && {
    echo "\n\033[33;1mThe command \"$@\" failed 3 times.\033[0m\n" >&2
  }

  return $result
}

# Taken from https://github.com/vcr/vcr/commit/fa96819c92b783ec0c794f788183e170e4f684b2
# and https://github.com/vcr/vcr/commit/040aaac5370c68cd13c847c076749cd547a6f9b1
nano_cmd="$(type -p gdate date | head -1)"
nano_format="+%s%N"
[ "$(uname -s)" != "Darwin" ] || nano_format="${nano_format/%N/000000000}"

travis_time_start() {
  travis_timer_id=$(printf %08x $(( RANDOM * RANDOM )))
  travis_start_time=$($nano_cmd -u "$nano_format")
  printf "travis_time:start:%s\r\e[0m" $travis_timer_id
}

travis_time_finish() {
  local travis_end_time=$($nano_cmd -u "$nano_format")
  local duration=$(($travis_end_time-$travis_start_time))
  printf "travis_time:end:%s:start=%s,finish=%s,duration=%s\r\e[0m" \
    $travis_timer_id $travis_start_time $travis_end_time $duration
}

fold() {
  local name="$1"
  local status=0
  shift 1
  if [ -n "$TRAVIS" ]; then
    printf "travis_fold:start:%s\r\e[0m" "$name"
    travis_time_start
  else
    echo "============= Starting $name ==============="
  fi

  "$@"
  status=$?

  [ -z "$TRAVIS" ] || travis_time_finish

  if [ "$status" -eq 0 ]; then
    if [ -n "$TRAVIS" ]; then
      printf "travis_fold:end:%s\r\e[0m" "$name"
    else
      echo "============= Ending $name ==============="
    fi
  else
    STATUS="$status"
  fi

  return $status
}
