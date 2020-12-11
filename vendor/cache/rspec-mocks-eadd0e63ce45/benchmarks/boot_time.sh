time (for i in {1..100}; do ruby -Ilib:../rspec-support/lib -rrspec/mocks -e ""; done)

# 3 runs before our autoload changes
# real  0m4.497s
# user  0m3.662s
# sys 0m0.677s
#
# real  0m4.472s
# user  0m3.644s
# sys 0m0.671s
#
# real  0m4.465s
# user  0m3.640s
# sys 0m0.668s

# 3 runs after our autoload changes:
#
# real  0m4.038s
# user  0m3.274s
# sys 0m0.609s
#
# real  0m4.038s
# user  0m3.274s
# sys 0m0.609s
#
# real  0m4.038s
# user  0m3.274s
# sys 0m0.609s

# It's modest, but that's about a 10% improvement: an average
# of about 40ms to load rather than 45 ms to load.
