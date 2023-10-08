# frozen_string_literal: true

require "yaml"
require "erb"

module Gemstash
  # :nodoc:
  class Configuration
    DEFAULTS = {
      cache_type: "memory",
      base_path: File.expand_path("~/.gemstash"),
      db_adapter: "sqlite3",
      bind: "tcp://0.0.0.0:9292",
      rubygems_url: "https://rubygems.org",
      ignore_gemfile_source: false,
      protected_fetch: false,
      fetch_timeout: 20,
      # Actual default for db_connection_options is dynamic based on the adapter
      db_connection_options: {},
      puma_threads: 16,
      puma_workers: 1,
      cache_expiration: 30 * 60,
      cache_max_size: 500
    }.freeze

    DEFAULT_FILE = File.expand_path("~/.gemstash/config.yml").freeze

    # This error is thrown when a config file is explicitly specified that
    # doesn't exist.
    class MissingFileError < StandardError
      def initialize(file)
        super("Missing config file: #{file}")
      end
    end

    def initialize(file: nil, config: nil)
      if config
        @config = DEFAULTS.merge(config).freeze
        return
      end

      raise MissingFileError, file if file && !File.exist?(file)

      file ||= default_file

      if File.exist?(file)
        @config = parse_config(file)
        @config = DEFAULTS.merge(@config)
        @config.freeze
      else
        @config = DEFAULTS
      end
    end

    def default?(key)
      @config[key] == DEFAULTS[key]
    end

    def [](key)
      @config[key]
    end

    # @return [Hash] Sequel connection configuration hash
    def database_connection_config
      case self[:db_adapter]
      when "sqlite3"
        { max_connections: 1 }.merge(self[:db_connection_options])
      when "postgres", "mysql", "mysql2"
        { max_connections: (self[:puma_workers] * self[:puma_threads]) + 1 }.merge(self[:db_connection_options])
      else
        raise "Unsupported DB adapter: '#{self[:db_adapter]}'"
      end
    end

  private

    def default_file
      # Support the config file being specified via environment variable
      gemstash_config = ENV["GEMSTASH_CONFIG"]
      return gemstash_config if gemstash_config

      # If no environment variable is used, fall back to the normal defaults
      File.exist?("#{DEFAULT_FILE}.erb") ? "#{DEFAULT_FILE}.erb" : DEFAULT_FILE
    end

    def parse_config(file)
      if file.end_with?(".erb")
        YAML.load(ERB.new(File.read(file)).result) || {}
      else
        YAML.load_file(file) || {}
      end
    end
  end
end
