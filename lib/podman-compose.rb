#!/usr/bin/env ruby
require 'yaml'
require 'optparse'
require 'logger'

# Using a module to set up a namespace
module Podman
  # Heres where the meat is
  class Compose
    def initialize(args)
      @cli_string = ''
      @logger = Logger.new(STDOUT)
      options = {}

      # Parse my arguments
      OptionParser.new do |opts|
        opts.banner = 'Usage: podman-compose cmd [options]'

        opts.on('-v', String, 'Show verbose output') do |_v|
          @logger.level = Logger::DEBUG
        end
        opts.on('-f', String, 'Specify which compose file to run (default is ./docker-compose.yml)') do |v|
          options[:file] = v
        end
        opts.on('-w', 'Watch logs for services') do |_w|
          options[:watch] = true
        end
        opts.on('-h', '--help', 'Prints this help') do
          puts opts
          exit
        end

        # set up my help message for later if necessary
        options[:help] = opts.help
      end.parse!

      case args.first.downcase
      when 'up'
        @cmd = :up
      when 'down'
        @cmd = :down
      when 'build'
        @cmd = :build
      else
        puts options[:help]
        exit
      end
    end

    def execute
      case @cmd
      when :up
        puts "You put #{:up}"
      when :down
      end
    end

    private

  end
end
