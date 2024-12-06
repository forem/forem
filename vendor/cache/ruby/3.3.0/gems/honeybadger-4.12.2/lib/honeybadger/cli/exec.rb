require 'erb'
require 'forwardable'
require 'honeybadger/cli/main'
require 'honeybadger/cli/helpers'
require 'honeybadger/util/http'
require 'honeybadger/util/stats'
require 'open3'
require 'ostruct'
require 'thor/shell'

module Honeybadger
  module CLI
    class Exec
      extend Forwardable
      include Helpers::BackendCmd

      FAILED_TEMPLATE = <<-MSG
Honeybadger detected failure or error output for the command:
`<%= args.join(' ') %>`

PROCESS ID: <%= pid %>

RESULT CODE: <%= code %>

ERROR OUTPUT:
<%= stderr %>

STANDARD OUTPUT:
<%= stdout %>
MSG

      NO_EXEC_TEMPLATE = <<-MSG
Honeybadger failed to execute the following command:
`<%= args.join(' ') %>`

The command was not executable. Try adjusting permissions on the file.
MSG

      NOT_FOUND_TEMPLATE = <<-MSG
Honeybadger failed to execute the following command:
`<%= args.join(' ') %>`

The command was not found. Make sure it exists in your PATH.
MSG

      def initialize(options, args, config)
        @options = options
        @args = args
        @config = config
        @shell = ::Thor::Base.shell.new
      end

      def run
        result = exec_cmd
        return if result.success

        executable = args.first.to_s[/\S+/]
        payload = {
          api_key: config.get(:api_key),
          notifier: NOTIFIER,
          error: {
            class: 'honeybdager exec error',
            message: result.msg
          },
          request: {
            component: executable,
            context: {
              command: args.join(' '),
              code: result.code,
              pid: result.pid,
              pwd: Dir.pwd,
              path: ENV['PATH']
            }
          },
          server: {
            project_root: Dir.pwd,
            environment_name: config.get(:env),
            time: Time.now,
            stats: Util::Stats.all
          }
        }

        begin
          response = config.backend.notify(:notices, payload)
        rescue
          say(result.msg)
          raise
        end

        if !response.success?
          say(result.msg)
          say(error_message(response), :red)
          exit(1)
        end

        unless quiet?
          say(result.msg)
          say("\nSuccessfully notified Honeybadger")
        end

        exit(0)
      end

      private

      attr_reader :options, :args, :config

      def_delegator :@shell, :say

      def quiet?
        !!options[:quiet]
      end

      def exec_cmd
        stdout, stderr, status = Open3.capture3(args.join(' '))

        success = status.success? && stderr =~ BLANK
        pid = status.pid
        code = status.to_i
        msg = ERB.new(FAILED_TEMPLATE).result(binding) unless success

        OpenStruct.new(
          msg: msg,
          pid: pid,
          code: code,
          stdout: stdout,
          stderr: stderr,
          success: success
        )
      rescue Errno::EACCES, Errno::ENOEXEC
        OpenStruct.new(
          msg: ERB.new(NO_EXEC_TEMPLATE).result(binding),
          code: 126
        )
      rescue Errno::ENOENT
        OpenStruct.new(
          msg: ERB.new(NOT_FOUND_TEMPLATE).result(binding),
          code: 127
        )
      end
    end
  end
end
