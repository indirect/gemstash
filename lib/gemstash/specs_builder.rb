# frozen_string_literal: true

require "gemstash"
require "stringio"
require "zlib"

module Gemstash
  # Builds a Marshal'ed and GZipped array of arrays containing specs as:
  # [name, Gem::Version, platform]
  class SpecsBuilder
    include Gemstash::Env::Helper
    attr_reader :result

    def self.serve(app)
      prerelease = app.params.fetch(:prerelease, false)
      latest = app.params.fetch(:latest, false)
      app.content_type "application/octet-stream"
      new(app.auth, prerelease: prerelease, latest: latest).serve
    end

    def self.invalidate_stored
      storage = Gemstash::Storage.for("private").for("specs_collection")
      storage.resource("specs.4.8.gz").delete(:specs)
      storage.resource("latest_specs.4.8.gz").delete(:specs)
      storage.resource("prerelease_specs.4.8.gz").delete(:specs)
    end

    def initialize(auth, prerelease: false, latest: false)
      @auth = auth
      @prerelease = prerelease
      @latest = latest
    end

    def serve
      check_auth if gemstash_env.config[:protected_fetch]
      fetch_from_storage
      return result if result

      fetch_versions
      marshal
      gzip
      store_result
      result
    end

  private

    def storage
      @storage ||= Gemstash::Storage.for("private").for("specs_collection")
    end

    def fetch_resource
      if @latest
        storage.resource("latest_specs.4.8.gz")
      elsif @prerelease
        storage.resource("prerelease_specs.4.8.gz")
      else
        storage.resource("specs.4.8.gz")
      end
    end

    def fetch_from_storage
      specs = fetch_resource
      return unless specs.exist?(:specs)

      @result = specs.load(:specs).content(:specs)
    rescue StandardError
      # On the off-chance of a race condition between specs.exist? and specs.load
      @result = nil
    end

    def fetch_versions
      @versions = Gemstash::DB::Version.for_spec_collection(prerelease: @prerelease, latest: @latest).map(&:to_spec)
    end

    def marshal
      @marshal ||= Marshal.dump(@versions)
    end

    def gzip
      @result ||= begin
        output = StringIO.new
        gz = Zlib::GzipWriter.new(output)

        begin
          gz.write(@marshal)
        ensure
          gz.close
        end

        output.string
      end
    end

    def store_result
      fetch_resource.save(specs: @result)
    end

    def check_auth
      @auth.check("fetch")
    end
  end
end
