#!/usr/bin/env ruby
require 'yaml'
require 'optparse'
require 'logger'
require 'pry'
require 'pp'

# Using a module to set up a namespace
module Podman
  # Heres where the meat is
  class Compose
    def initialize(args)
      @cli_strings = {}
      @logger = Logger.new(STDOUT)
      @options = {}

      # Parse my arguments
      # THIS ISN'T WORKING YET. I'LL GET TO IT WHEN I GET BASE FUNCTIONALITY WORKING.
      OptionParser.new do |opts|
        opts.banner = 'Usage: podman-compose cmd [options]'

        opts.on('-v', 'Show verbose output') do |_v|
          @logger.level = Logger::DEBUG
        end
        opts.on('-f', 'Specify which compose file to run (default is ./docker-compose.yml)') do |v|
          @options[:file] = v
        end
        opts.on('-w', 'Watch logs for services') do |_w|
          @options[:watch] = true
        end
        opts.on('-h', '--help', 'Prints this help') do
          puts opts
          exit
        end

        # set up my help message for later if necessary
        @options[:help] = opts.help
      end.parse!(into: @options)

      case args.first.downcase
      when 'up'
        @cmd = :up
      when 'down'
        @cmd = :down
      when 'build'
        @cmd = :build
      else
        puts @options[:help]
        exit
      end
    end

    def parse_compose_file
      # Read in the compose.yml file, either specified via cli arg or just using the default
      compose_file = YAML.load_file(@options[:file].nil? ? "./docker-compose.yml" : @options[:file])
      # Symbolize the keys just to make life a bit easier
      compose_file = symbolize_keys(compose_file)

      case @cmd
      when :up
        # Go through each of the services, creating a "podman run" command
        compose_file[:services].keys.each do |service_name|
          service = compose_file[:services][service_name.to_sym]
          ####
          # Off to the races...
          ####
          @cli_strings[service_name] = []
          # service name:
          @cli_strings[service_name] << "--name #{service_to_container_name(service_name)}"
          # environment:
          @cli_strings[service_name] << service[:environment].map{|var| "-e #{var}"}.join(" ") unless service[:environment].nil?
          # volumes:
          @cli_strings[service_name] << service[:volumes].map{|vol| "-v #{vol}"}.join(" ") unless service[:volumes].nil?
          ### Create the volume paths
          service[:volumes].each do |volume|
            myvol = volume.split(":").first
            Dir.mkdir(myvol) unless Dir.exist?(myvol)
          end

          # ports:
          @cli_strings[service_name] << service[:ports].map{|port| "-p #{port}"}.join(" ") unless service[:ports].nil?
          # privileged
          @cli_strings[service_name] << "--privileged" if service[:privileged]
          # host network because podman doesn't have the concept of creating a new network
          @cli_strings[service_name] << "--net=host"
          # @cli_strings[service_name] << "--net=container:#{service_to_container_name(service[:links].first)}" unless service[:links].nil?

          # image:
          @cli_strings[service_name] << service[:image]
        end

        # Map the keys to super nice command strings to run
        @cli_strings.transform_values! { |cmd| "podman run -d #{cmd.join(" ")}" }
      when :down
        compose_file[:services].keys.each do |service_name|
          @cli_strings[service_name] = []
          @cli_strings[service_name] << service_to_container_name(service_name)
        end

        # Map the keys to super nice command strings to run
        @cli_strings.transform_values! { |cmd| "podman stop #{cmd.join(" ")}" }
      when :build
        puts "Not implemented yet!"
        exit
      end

      # pp @cli_strings
      @cli_strings
    end

    def execute
      @cli_strings.each do |pod, str|
        puts "Running cmd on pod #{pod}"
        puts "#### "  + str
        system(str)
      end
    end

    private

    # Get the name for the container in the form "dir_containername"
    def service_to_container_name(service_name)
      [File.basename(Dir.getwd), service_name].join("_")
    end

    # If I had rails I wouldn't have had to copy/paste this BS. But so be it.
    def symbolize_keys(hash)
      Hash[ hash.map { |k,v| v.is_a?(Hash) ? [k.to_sym, symbolize_keys(v)] : [k.to_sym,v] } ]
    end
  end
end
