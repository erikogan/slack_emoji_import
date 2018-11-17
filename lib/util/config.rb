# frozen_string_literal: true

require 'json'
require 'active_support/core_ext/hash/keys' # symbolize_keys

require 'faraday'
require 'faraday_middleware'
require 'typhoeus'
require 'typhoeus/adapters/faraday'
require 'typhoeus/hydra'

require 'util/config/browser'

require 'byebug'

module Util
  # Class to manage Slack API configurations and endpoint data caches
  class Config
    include Browser

    API_BASE_URL = 'https://slack.com/api/emoji.list'
    attr_reader :name, :token, :username, :source, :manual_login

    def initialize(name:, token:, url: nil, username: nil, password: nil, source: false, manual_login: false)
      @name = name
      @token = token
      @url = url
      @username = username
      @password = password
      @source = source
      @manual_login = manual_login
    end

    def self.from_credentials(name, data)
      new(name: name, **data.symbolize_keys)
    end

    def url
      @url || @name
    end

    def password
      return @password if @password

      @password = [
        "_#{name.upcase}",
        "_#{url.upcase}",
        ''
      ].map { |x| ENV["SLACK_PASSWORD#{x}"] }.compact.first || abort("No password found for #{url}")
    end

    def cached_data_and_images
      result = {}

      Util.parallel_image_cache(cached_data['emoji']) do |info|
        result[info[:name]] = info
      end

      result
    end

    def cached_data
      Util.ensure_directories

      fresh = fresh_cache_file

      if fresh
        JSON.parse(File.read(fresh))
      else
        puts "Fetching updated data for #{name}"
        live_data
      end
    end

    def live_data
      resp = self.class.api_connection.get do |req|
        req.params['token'] = token
      end

      # TODO: raise on failure
      File.write(cache_file, resp.body.to_json)
      resp.body
    end

    def fresh_cache_file
      stat = begin
               File.stat(cache_file)
             rescue Errno::ENOENT
               nil
             end
      return nil unless stat
      return nil if stat.mtime < Time.now - 24 * 60 * 60

      cache_file
    end

    def cache_file
      File.join('data', 'raw', "#{name}.json")
    end

    @api_connection = nil

    def self.api_connection
      @api_connection ||= Faraday.new(url: API_BASE_URL, parallel_manager: HYDRA) do |builder|
        builder.request  :url_encoded
        builder.response :json, content_type: /\bjson$/
        builder.adapter  :typhoeus
      end
    end
  end
end
