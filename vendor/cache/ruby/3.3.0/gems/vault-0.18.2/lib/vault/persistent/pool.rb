# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

module Vault
class PersistentHTTP::Pool < Vault::ConnectionPool # :nodoc:

  attr_reader :available # :nodoc:
  attr_reader :key # :nodoc:

  def initialize(options = {}, &block)
    super

    @available = PersistentHTTP::TimedStackMulti.new(@size, &block)
    @key = :"current-#{@available.object_id}"
  end

  def checkin net_http_args
    stack = Thread.current[@key][net_http_args]

    raise ConnectionPool::Error, 'no connections are checked out' if
      stack.empty?

    conn = stack.pop

    if stack.empty?
      @available.push conn, connection_args: net_http_args
    end

    nil
  end

  def checkout net_http_args
    stacks = Thread.current[@key] ||= Hash.new { |h, k| h[k] = [] }
    stack  = stacks[net_http_args]

    if stack.empty? then
      conn = @available.pop @timeout, connection_args: net_http_args
    else
      conn = stack.last
    end

    stack.push conn

    conn
  end

end
end

require_relative 'timed_stack_multi'

