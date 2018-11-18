#!/usr/bin/env ruby
# frozen_string_literal: true

require 'byebug'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'lib')
require 'util'

class Importer
  include Util

  def run
    @source_data.each do |name, data|
      next if data[:alias]
      next if @disabled.include?(name)

      if @dest_data.key?(name)
        warn "WARNING: #{name} differs, but not replacing" if dest_data[name][:md5] != data[:md5]
        next
      end
      puts name
      add_with_retries(name, data)
    end
    sleep 2
  end

  def add_with_retries(name, data)
    try = 0
    begin
      @dest.add_emoji(name, data[:file])
    rescue Selenium::WebDriver::Error::UnknownError => e
      try += 1
      raise e if try > 10

      sleep 1
      puts 'RETRY!'
      retry
    end
  end

  def initialize(dest, source = nil)
    setup_dest(dest)
    setup_source(source)
    setup_disabled(dest)
  end

  def setup_dest(dest)
    @dest = configs[dest.to_sym] || raise("no such workspace: #{dest}")
    @dest_data = @dest.cached_data_and_images
  end

  def setup_source(source)
    @source = source ? configs[source.to_sym] || raise("no such workspace #{source}") : configs[:_source]
    @source_data = @source.cached_data_and_images
  end

  def setup_disabled(dest)
    @disabled = YAML.safe_load(File.read('data/disabled.yml'))
    @disabled += YAML.safe_load(File.read("data/disabled.#{dest}.yml")) if File.exist?("data/disabled.#{dest}.yml")
  end
end

Importer.new(*ARGV).run

# TODO: Incorporate
# ensure
#   driver.quit
# end
