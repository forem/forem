ruby -v

function run_benchmark_with_load_path_size {
  pushd tmp
  mkdir -p boot_time_benchmark

  local load_path_size=$1
  for (( i=0; i < $load_path_size; i++ )); do
    mkdir -p "boot_time_benchmark/dir_$i"
  done

  local load_path=`ruby -e 'puts Array.new(Integer(ARGV.first)) { |i| "boot_time_benchmark/dir_#{i}" }.join(":")' $load_path_size`

  echo "3 runs with $load_path_size dirs on load path, booting 50 times, using $2"
  for i in {1..3}; do
    time (for i in {1..50}; do ruby -I$load_path:../lib:../../rspec-support/lib -e 'require "rspec/core"'; done)
  done
  popd
}

run_benchmark_with_load_path_size 10   "require"
run_benchmark_with_load_path_size 100  "require"
run_benchmark_with_load_path_size 1000 "require"

export REQUIRE_RELATIVE=1

run_benchmark_with_load_path_size 10   "require_relative"
run_benchmark_with_load_path_size 100  "require_relative"
run_benchmark_with_load_path_size 1000 "require_relative"

: <<'result_comment'
ruby 2.0.0p247 (2013-06-27 revision 41674) [x86_64-darwin12.4.0]
~/code/rspec-core/tmp ~/code/rspec-core
3 runs with 10 dirs on load path, booting 50 times, using require

real  0m3.815s
user  0m3.205s
sys 0m0.519s

real  0m3.850s
user  0m3.234s
sys 0m0.527s

real  0m3.840s
user  0m3.225s
sys 0m0.525s
~/code/rspec-core
~/code/rspec-core/tmp ~/code/rspec-core
3 runs with 100 dirs on load path, booting 50 times, using require

real  0m5.086s
user  0m3.887s
sys 0m1.107s

real  0m5.063s
user  0m3.870s
sys 0m1.098s

real  0m5.061s
user  0m3.871s
sys 0m1.097s
~/code/rspec-core
~/code/rspec-core/tmp ~/code/rspec-core
3 runs with 1000 dirs on load path, booting 50 times, using require

real  0m18.850s
user  0m11.057s
sys 0m7.679s

real  0m18.783s
user  0m11.012s
sys 0m7.657s

real  0m18.747s
user  0m10.992s
sys 0m7.639s
~/code/rspec-core
~/code/rspec-core/tmp ~/code/rspec-core
3 runs with 10 dirs on load path, booting 50 times, using require_relative

real  0m3.794s
user  0m3.200s
sys 0m0.506s

real  0m3.769s
user  0m3.180s
sys 0m0.502s

real  0m3.787s
user  0m3.192s
sys 0m0.502s
~/code/rspec-core
~/code/rspec-core/tmp ~/code/rspec-core
3 runs with 100 dirs on load path, booting 50 times, using require_relative

real  0m4.626s
user  0m3.620s
sys 0m0.910s

real  0m4.652s
user  0m3.642s
sys 0m0.915s

real  0m4.678s
user  0m3.662s
sys 0m0.924s
~/code/rspec-core
~/code/rspec-core/tmp ~/code/rspec-core
3 runs with 1000 dirs on load path, booting 50 times, using require_relative

real  0m14.400s
user  0m8.615s
sys 0m5.675s

real  0m14.495s
user  0m8.672s
sys 0m5.711s

real  0m14.541s
user  0m8.705s
sys 0m5.727s
~/code/rspec-core
result_comment
