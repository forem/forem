## 1.2.0 - June 13, 2021
- Improved handling of multiple machines
- Rescue StandardError instead of Exception

## 1.1.2 - August 4, 2019
- Rescue Errno::ENOTSOCK

## 1.1.1 - May 28, 2019
- Interval server synchronizes updates and ready state
- Spec and CI changes

## 1.1.0 - May 27, 2019
- Interval server uses threads for timing
- Servers use observer patterns to reduce polling

## 1.0.0 - February 19, 2019
- Renamed Adapter#sending to Adapter#receiving
- Travis tests up to Ruby 2.6

## 0.3.0 - January 10, 2019
- Basic logging
- Differentiate between "expected" and "unexpected" exceptions in Tcpip
- Prefer #start to #run for non-blocking client/server methods
- Interval servers can stop themselves

## 0.2.0 - December 21, 2018
- Minor bug fixes in STDIO server
- More efficient client reads
- Rename server methods `prepare` for clarity
- Improved socket state handling
- More accurate interval time
- Adapter#remote attribute
- Adapter#close method
- Socket exception handling

## 0.1.0 - December 20, 2018
First release
