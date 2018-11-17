# frozen_string_literal: true

require 'yaml'
require 'fileutils'
require 'digest'

require 'faraday'
require 'faraday_middleware'
require 'typhoeus'
require 'typhoeus/adapters/faraday'
require 'typhoeus/hydra'

require 'util/config'

require 'byebug'

module Util
  module_function

  EMOJI_BASE_URL = 'https://emoji.slack-edge.com'
  IMAGE_CACHE_DIR = 'tmp/cache'

  HYDRA = Typhoeus::Hydra.new(max_concurrency: 5)

  def configs
    @configs ||= begin
      Hash[credentials.map { |name, data| [name.to_sym, Config.from_credentials(name.to_sym, data)] }].tap do |h|
        h[:_source] = h.values.find(&:source)
      end
    end
  end

  def parallel_image_cache(name_to_url)
    responses = []

    image_connection.in_parallel do
      name_to_url.each do |name, url|
        if url =~ /^alias:(.*)/
          yield({ name: name, alias: Regexp.last_match(1) })
          next
        end

        base = url.gsub(%r{^#{EMOJI_BASE_URL}/}, '')
        cache = File.join(IMAGE_CACHE_DIR, base)

        md5_file = cache.gsub(/\.\w+$/, '.md5')

        if [cache, md5_file].all? { |f| File.exist?(f) }
          yield({ name: name, file: cache, md5: File.read(md5_file) })
        else
          responses << [name, cache, md5_file, image_connection.get(url)]
        end
      end
    end

    responses.each do |name, file, md5_file, response|
      abort "Unable to cache #{name} (#{file}): #{response.body}" unless response.success?
      FileUtils.mkdir_p File.dirname(file)
      File.write(file, response.body)
      md5 = Digest::MD5.hexdigest(response.body)
      File.write(md5_file, md5)
      yield({ name: name, file: file, md5: md5 })
    end
  end

  def image_connection
    @image_connection ||= Faraday.new(url: EMOJI_BASE_URL, parallel_manager: HYDRA) do |builder|
      builder.request  :url_encoded
      builder.adapter  :typhoeus
    end
  end

  def ensure_directories
    Dir.mkdir('data') unless File.directory?('data')
    Dir.mkdir('data/raw') unless File.directory?('data/raw')
  end

  def credentials
    @credentials ||= begin
      file = File.join(__dir__, '..', 'config', 'credentials.yml')
      YAML.safe_load(File.read(file))
    end
  end
end
