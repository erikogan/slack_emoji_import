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
  class Config
    include Browser

    API_BASE_URL = 'https://slack.com/api/emoji.list'
    attr_reader *%i{name token url username password source manual_login}

    def initialize(name:, token:, url: nil, username: nil, password: nil, source:false, manual_login:false)
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
      @password = ["_#{name.upcase}", "_#{url.upcase}", ''].map {|x| ENV["SLACK_PASSWORD#{x}"]}.compact.first || abort("No password found for #{url}")
    end

    def cached_data_and_images
      data = cached_data['emoji']
      responses = []
      connection = Util::image_connection

      result = {}

      Util::parallel_image_cache(data) do |info|
        result[info[:name]] = info
      end

      result
    end

    def cached_data
      Util::ensure_directories

      cache = File.join('data', 'raw', "#{name}.json")
      stat = begin
        File.stat(cache)
      rescue Errno::ENOENT
        nil
      end

      if !stat || stat.mtime < Time.now - 24 * 60 * 60
        puts "Fetching updated data for #{name}"
        live_data
      else
        JSON.load(File.read(cache))
      end
    end

    def live_data
      resp = self.class.api_connection.get do |req|
        req.params['token']  = token
      end

      # TODO: raise on failure
      File.write("data/raw/#{name}.json", resp.body.to_json)
      resp.body
    end

    @@api_connection = nil

    def self.api_connection
      @@api_connection ||= Faraday.new(url: API_BASE_URL, parallel_manager: HYDRA) do |builder|
        builder.request  :url_encoded
        builder.response :json, content_type: /\bjson$/
        builder.adapter  :typhoeus
      end
    end
  end
end
