# NEWS

## Version 0.5.0 (2024-03-27)

### Improvements

* Allow case-insensitive strings for SASL mechanism <https://github.com/ruby/net-smtp/pull/64>
* Make #auth_capable? public <https://github.com/ruby/net-smtp/pull/63>
* Add XOAUTH2 authenticator <https://github.com/ruby/net-smtp/pull/80>

### Others

* Remove unused private auth_method <https://github.com/ruby/net-smtp/pull/67>
* Delegate checking auth args to the authenticator <https://github.com/ruby/net-smtp/pull/73>
* Updated docs, especially TLS and SASL-related <https://github.com/ruby/net-smtp/pull/66>
* Renew test certificates <https://github.com/ruby/net-smtp/pull/75>
* Fix version extraction to work with non ASCII characters with any LANG <https://github.com/ruby/net-smtp/pull/76>
* Replace non-ASCII EM DASH (U+2014) with ASCII hyphen (U+002D) <https://github.com/ruby/net-smtp/pull/78>
* Use reusing workflow for Ruby versions <https://github.com/ruby/net-smtp/pull/79>
* Make the test suite compatible with --enable-frozen-string-literal <https://github.com/ruby/net-smtp/pull/81>

## Version 0.4.0 (2023-09-20)

### Improvements

* add Net::SMTP::Authenticator class and auth_* methods are separated from the Net::SMTP class. <https://github.com/ruby/net-smtp/pull/53>
      This allows you to add a new authentication method to Net::SMTP.
      Create a class with an `auth` method that inherits Net::SMTP::Authenticator.
      The `auth` method has two arguments, `user` and `secret`.
      Send an instruction to the SMTP server by using the `continue` or `finish` method.
      For more information, see lib/net/smtp/auto _*.rb.
* Add SMTPUTF8 support <https://github.com/ruby/net-smtp/pull/49>

### Fixes

* Revert "Replace Timeout.timeout with socket timeout" <https://github.com/ruby/net-smtp/pull/51>
* Fixed issue sending emails to unaffected recipients on 53x error <https://github.com/ruby/net-smtp/pull/56>

### Others

* Removed unnecessary Subversion keywords <https://github.com/ruby/net-smtp/pull/57>

## Version 0.3.3 (2022-10-29)

* No timeout library required <https://github.com/ruby/net-smtp/pull/44>
* Make the digest library optional <https://github.com/ruby/net-smtp/pull/45>

## Version 0.3.2 (2022-09-28)

* Make exception API compatible with what Ruby expects <https://github.com/ruby/net-smtp/pull/42>

## Version 0.3.1 (2021-12-12)

### Improvements

* add Net::SMTP::Address.
* add Net::SMTP#capable? and Net::SMTP#capabilities.
* add Net::SMTP#tls_verify, Net::SMTP#tls_hostname, Net::SMTP#ssl_context_params

## Version 0.3.0 (2021-10-14)

### Improvements

* Add `tls`, `starttls` keyword arguments.
    ```ruby
    # always use TLS connection for port 465.
    Net::SMTP.start(hostname, 465, tls: true)

    # do not use starttls for localhost
    Net::SMTP.start('localhost', starttls: false)
    ```

### Incompatible changes

* The tls_* paramter has been moved from start() to initialize().

## Version 0.2.2 (2021-10-09)

* Add `response` to SMTPError exceptions.
* `Net::SMTP.start()` and `#start()` accepts `ssl_context_params` keyword argument.
* Replace `Timeout.timeout` with socket timeout.
* Remove needless files from gem.
* Add dependency on digest, timeout.

## Version 0.2.1 (2020-11-18)

### Fixes

* Update the license for the default gems to dual licenses.
* Add dependency for net-protocol.

## Version 0.2.0 (2020-11-15)

### Incompatible changes

* Verify the server's certificate by default.
  If you don't want verification, specify `start(tls_verify: false)`.
  <https://github.com/ruby/net-smtp/pull/12>

* Use STARTTLS by default if possible.
  If you don't want starttls, specify:
      ```
      smtp = Net::SMTP.new(hostname, port)
      smtp.disable_starttls
      smtp.start do |s|
        s.send_message ....
      end
      ```
  <https://github.com/ruby/net-smtp/pull/9>

### Improvements

* Net::SMTP.start and Net::SMTP#start arguments are keyword arguments.
      ```
      start(address, port = nil, helo: 'localhost', user: nil, secret: nil, authtype: nil) { |smtp| ... }
      ```
  `password` is an alias of `secret`.
  <https://github.com/ruby/net-smtp/pull/7>

* Add `tls_hostname` parameter to `start()`.
  If you want to use a different hostname than the certificate for the connection, you can specify the certificate hostname with `tls_hostname`.
  <https://github.com/ruby/net-smtp/pull/14>

* Add SNI support to net/smtp <https://github.com/ruby/net-smtp/pull/4>

### Fixes

* enable_starttls before disable_tls causes an error. <https://github.com/ruby/net-smtp/pull/10>
* TLS should not check the hostname when verify_mode is disabled. <https://github.com/ruby/net-smtp/pull/6>

## Version 0.1.0 (2019-12-03)

This is the first release of net-smtp gem.
