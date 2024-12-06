#!/usr/bin/env ruby
### http://mput.dip.jp/mput/uuid.txt

# Copyright(c) 2005 URABE, Shyouhei.
#
# Permission is hereby granted, free of  charge, to any person obtaining a copy
# of  this code, to  deal in  the code  without restriction,  including without
# limitation  the rights  to  use, copy,  modify,  merge, publish,  distribute,
# sublicense, and/or sell copies of the code, and to permit persons to whom the
# code is furnished to do so, subject to the following conditions:
#
#        The above copyright notice and this permission notice shall be
#        included in all copies or substantial portions of the code.
#
# THE  CODE IS  PROVIDED "AS  IS",  WITHOUT WARRANTY  OF ANY  KIND, EXPRESS  OR
# IMPLIED,  INCLUDING BUT  NOT LIMITED  TO THE  WARRANTIES  OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE  AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
# AUTHOR  OR  COPYRIGHT  HOLDER BE  LIABLE  FOR  ANY  CLAIM, DAMAGES  OR  OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF  OR IN CONNECTION WITH  THE CODE OR THE  USE OR OTHER  DEALINGS IN THE
# CODE.
#
# 2009-02-20:  Modified by Pablo Lorenzoni <pablo@propus.com.br>  to  correctly
# include the version in the raw_bytes.


require 'digest/md5'
require 'digest/sha1'
require 'tmpdir'

module JSON
  module Util
  
    # Pure ruby UUID generator, which is compatible with RFC4122
    UUID = Struct.new :raw_bytes
  
    class UUID
    	private_class_method :new

    	class << self
    		def mask19 v, str # :nodoc
    			nstr = str.bytes.to_a
    			version = [0, 16, 32, 48, 64, 80][v]
    			nstr[6] &= 0b00001111
    			nstr[6] |= version
    #			nstr[7] &= 0b00001111
    #			nstr[7] |= 0b01010000
    			nstr[8] &= 0b00111111
    			nstr[8] |= 0b10000000
    			str = ''
    			nstr.each { |s| str << s.chr }
    			str
    		end

    		def mask18 v, str # :nodoc
    			version = [0, 16, 32, 48, 64, 80][v]
    			str[6] &= 0b00001111
    			str[6] |= version
    #			str[7] &= 0b00001111
    #			str[7] |= 0b01010000
    			str[8] &= 0b00111111
    			str[8] |= 0b10000000
    			str
    		end

    		def mask v, str
    			if RUBY_VERSION >= "1.9.0"
    				return mask19 v, str
    			else
    				return mask18 v, str
    			end
    		end
    		private :mask, :mask18, :mask19

    		# UUID generation using SHA1. Recommended over create_md5.
    		# Namespace object is another UUID, some of them are pre-defined below.
    		def create_sha1 str, namespace
    			sha1 = Digest::SHA1.new
    			sha1.update namespace.raw_bytes
    			sha1.update str
    			sum = sha1.digest
    			raw = mask 5, sum[0..15]
    			ret = new raw
    			ret.freeze
    			ret
    		end
    		alias :create_v5 :create_sha1

    		# UUID generation using MD5 (for backward compat.)
    		def create_md5 str, namespace
    			md5 = Digest::MD5.new
    			md5.update namespace.raw_bytes
    			md5.update str
    			sum = md5.digest
    			raw = mask 3, sum[0..16]
    			ret = new raw
    			ret.freeze
    			ret
    		end
    		alias :create_v3 :create_md5

    		# UUID  generation  using  random-number  generator.   From  it's  random
    		# nature, there's  no warranty that  the created ID is  really universaly
    		# unique.
    		def create_random
    			rnd = [
    				rand(0x100000000),
    				rand(0x100000000),
    				rand(0x100000000),
    				rand(0x100000000),
    			].pack "N4"
    			raw = mask 4, rnd
    			ret = new raw
    			ret.freeze
    			ret
    		end
    		alias :create_v4 :create_random

    		def read_state fp			  # :nodoc:
    			fp.rewind
    			Marshal.load fp.read
    		end

    		def write_state fp, c, m  # :nodoc:
    			fp.rewind
    			str = Marshal.dump [c, m]
    			fp.write str
    		end

    		private :read_state, :write_state
    		STATE_FILE = 'ruby-uuid'

    		# create  the "version  1" UUID  with current  system clock,  current UTC
    		# timestamp, and the IEEE 802 address (so-called MAC address).
    		#
    		# Speed notice: it's slow.  It writes  some data into hard drive on every
    		# invokation. If you want to speed  this up, try remounting tmpdir with a
    		# memory based filesystem  (such as tmpfs).  STILL slow?  then no way but
    		# rewrite it with c :)
    		def create clock=nil, time=nil, mac_addr=nil
    			c = t = m = nil
    			Dir.chdir Dir.tmpdir do
    				unless FileTest.exist? STATE_FILE then
    					# Generate a pseudo MAC address because we have no pure-ruby way
    					# to know  the MAC  address of the  NIC this system  uses.  Note
    					# that cheating  with pseudo arresses here  is completely legal:
    					# see Section 4.5 of RFC4122 for details.
    					sha1 = Digest::SHA1.new
    					256.times do
    						r = [rand(0x100000000)].pack "N"
    						sha1.update r
    					end
    					str = sha1.digest
    					r = rand 14 # 20-6
    					node = str[r, 6] || str
    					if RUBY_VERSION >= "1.9.0"
    						nnode = node.bytes.to_a
    						nnode[0] |= 0x01
    						node = ''
    						nnode.each { |s| node << s.chr }
    					else
    						node[0] |= 0x01 # multicast bit
    					end
    					k = rand 0x40000
    					open STATE_FILE, 'w' do |fp|
    						fp.flock IO::LOCK_EX
    						write_state fp, k, node
    						fp.chmod 0o777 # must be world writable
    					end
    				end
    				open STATE_FILE, 'r+' do |fp|
    					fp.flock IO::LOCK_EX
    					c, m = read_state fp
    					c = clock % 0x4000 if clock
    					m = mac_addr if mac_addr
    					t = time
    					if t.nil? then
    						# UUID epoch is 1582/Oct/15
    						tt = Time.now
    						t = tt.to_i*10000000 + tt.tv_usec*10 + 0x01B21DD213814000
    					end
    					c = c.succ # important; increment here
    					write_state fp, c, m
    				end
    			end

    			tl = t & 0xFFFF_FFFF
    			tm = t >> 32
    			tm = tm & 0xFFFF
    			th = t >> 48
    			th = th & 0x0FFF
    			th = th | 0x1000
    			cl = c & 0xFF
    			ch = c & 0x3F00
    			ch = ch >> 8
    			ch = ch | 0x80
    			pack tl, tm, th, cl, ch, m
    		end
    		alias :create_v1 :create

    		# A  simple GUID  parser:  just ignores  unknown  characters and  convert
    		# hexadecimal dump into 16-octet object.
    		def parse obj
    			str = obj.to_s.sub %r/\Aurn:uuid:/, ''
    			str.gsub! %r/[^0-9A-Fa-f]/, ''
    			raw = str[0..31].lines.to_a.pack 'H*'
    			ret = new raw
    			ret.freeze
    			ret
    		end

    		# The 'primitive constructor' of this class
    		# Note UUID.pack(uuid.unpack) == uuid
    		def pack tl, tm, th, ch, cl, n
    			raw = [tl, tm, th, ch, cl, n].pack "NnnCCa6"
    			ret = new raw
    			ret.freeze
    			ret
    		end
    	end

    	# The 'primitive deconstructor', or the dual to pack.
    	# Note UUID.pack(uuid.unpack) == uuid
    	def unpack
    		raw_bytes.unpack "NnnCCa6"
    	end

    	# Generate the string representation (a.k.a GUID) of this UUID
    	def to_s
    		a = unpack
    		tmp = a[-1].unpack 'C*'
    		a[-1] = sprintf '%02x%02x%02x%02x%02x%02x', *tmp
    		"%08x-%04x-%04x-%02x%02x-%s" % a
    	end
    	alias guid to_s

    	# Convert into a RFC4122-comforming URN representation
    	def to_uri
    		"urn:uuid:" + self.to_s
    	end
    	alias urn to_uri

    	# Convert into 128-bit unsigned integer
    	def to_int
    		tmp = self.raw_bytes.unpack "C*"
    		tmp.inject do |r, i|
    			r * 256 | i
    		end
    	end
    	alias to_i to_int

    	# Gets the version of this UUID
    	# returns nil if bad version
    	def version
    		a = unpack
    		v = (a[2] & 0xF000).to_s(16)[0].chr.to_i
    		return v if (1..5).include? v
    		return nil
    	end

    	# Two  UUIDs  are  said  to  be  equal if  and  only  if  their  (byte-order
    	# canonicalized) integer representations are equivallent.  Refer RFC4122 for
    	# details.
    	def == other
    		to_i == other.to_i
    	end

    	include Comparable
    	# UUIDs are comparable (don't know what benefits are there, though).
    	def <=> other
    		to_s <=> other.to_s
    	end

    	# Pre-defined UUID Namespaces described in RFC4122 Appendix C.
    	NameSpace_DNS = parse "6ba7b810-9dad-11d1-80b4-00c04fd430c8"
    	NameSpace_URL = parse "6ba7b811-9dad-11d1-80b4-00c04fd430c8"
    	NameSpace_OID = parse "6ba7b812-9dad-11d1-80b4-00c04fd430c8"
    	NameSpace_X500 = parse "6ba7b814-9dad-11d1-80b4-00c04fd430c8"

    	# The Nil UUID in RFC4122 Section 4.1.7
    	Nil = parse "00000000-0000-0000-0000-000000000000"
    end
  end
end