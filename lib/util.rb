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

# Util methods to abstract some of the complexity of common functionality
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
        # If the item is an alias, or already cached, we do not need to fetch it again.
        data = alias_or_cached_data(name, url)
        if data
          yield data
          next
        end

        responses << [name, cache_file(url), md5_file(url), image_connection.get(url)]
      end
    end

    handle_parallel_responses(responses, Proc.new) unless responses.empty?
  end

  def cache_file(url)
    File.join(IMAGE_CACHE_DIR, url.gsub(%r{^#{EMOJI_BASE_URL}/}, ''))
  end

  def md5_file(url)
    cache_file(url).gsub(/\.\w+$/, '.md5')
  end

  def alias_or_cached_data(name, url)
    return { name: name, alias: Regexp.last_match(1) } if url =~ /^alias:(.*)/

    cache = cache_file(url)
    md5 = md5_file(url)
    return { name: name, file: cache, md5: File.read(md5) } if [cache, md5].all? { |f| File.exist?(f) }

    nil
  end

  def handle_parallel_responses(responses, block)
    responses.each do |name, file, md5_file, response| # rubocop:disable Metrics/ParameterLists
      abort "Unable to cache #{name} (#{file}): #{response.body}" unless response.success?
      FileUtils.mkdir_p File.dirname(file)
      File.write(file, response.body)
      md5 = Digest::MD5.hexdigest(response.body)
      File.write(md5_file, md5)
      block.call(name: name, file: file, md5: md5)
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
