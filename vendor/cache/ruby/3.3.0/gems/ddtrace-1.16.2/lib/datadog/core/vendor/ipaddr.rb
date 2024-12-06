# Copyright (c) 2002 Hajimu UMEMOTO <ume@mahoroba.org>
# Copyright (c) 2007-2017 Akinori MUSHA <knu@iDaemons.org>

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.

# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

module Datadog
  module Core
    module Vendor
      # vendor code from https://github.com/ruby/ipaddr/blob/master/lib/ipaddr.rb
      # Ruby version below 2.5 does not have the IpAddr#private? method
      # We have to vendor the code because ruby versions below 2.5 did not extract ipaddr as a gem
      # So we can not specify a specific version for ipaddr for ruby versions: 2.1, 2.2, 2.3, 2.4
      module IPAddr
        class << self
          def private?(ip)
            addr = ip.instance_variable_get(:@addr)

            case ip.family
            when Socket::AF_INET
              addr & 0xff000000 == 0x0a000000 ||    # 10.0.0.0/8
                addr & 0xfff00000 == 0xac100000 ||  # 172.16.0.0/12
                addr & 0xffff0000 == 0xc0a80000     # 192.168.0.0/16
            when Socket::AF_INET6
              addr & 0xfe00_0000_0000_0000_0000_0000_0000_0000 == 0xfc00_0000_0000_0000_0000_0000_0000_0000
            else
              raise ::IPAddr::AddressFamilyError, 'unsupported address family'
            end
          end

          def link_local?(ip)
            addr = ip.instance_variable_get(:@addr)

            case ip.family
            when Socket::AF_INET
              addr & 0xffff0000 == 0xa9fe0000 # 169.254.0.0/16
            when Socket::AF_INET6
              addr & 0xffc0_0000_0000_0000_0000_0000_0000_0000 == 0xfe80_0000_0000_0000_0000_0000_0000_0000
            else
              raise ::IPAddr::AddressFamilyError, 'unsupported address family'
            end
          end

          def loopback?(ip)
            addr = ip.instance_variable_get(:@addr)

            case ip.family
            when Socket::AF_INET
              addr & 0xff000000 == 0x7f000000
            when Socket::AF_INET6
              addr == 1
            else
              raise ::IPAddr::AddressFamilyError, 'unsupported address family'
            end
          end
        end
      end
    end
  end
end
