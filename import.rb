#!/usr/bin/env ruby
# frozen_string_literal: true

require 'byebug'

$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'util'

class Importer
  include Util

  def run
    source_data = @source.cached_data_and_images
    dest_data = @dest.cached_data_and_images

    # byebug ; 1

    try = 0
    source_data.each do |name, data|
      next if data[:alias]
      next if @removed.include?(name)
      if dest_data.key?(name)
        $stderr.puts "WARNING: #{name} differs, but not replacing" if dest_data[name][:md5] != data[:md5]
        next
      end
      puts name
      # byebug ; 1
      begin
        # @dest.add_emoji(name, data[:file])
      rescue Selenium::WebDriver::Error::UnknownError => e
        try += 1
        if try < 10
          sleep 1
          puts 'RETRY!'
          retry
        else
          raise e
        end
      end

      try = 0
      # sleep 1
    end
    sleep 2
  end

  def initialize(dest, source = nil)
    @dest = configs[dest.to_sym] || raise("no such workspace: #{dest}")
    @source = source ? configs[source.to_sym] || raise("no such workspace #{source}") : configs[:_source]
    @removed = YAML.safe_load(File.read('data/removed.yml'))
    if File.exist?("data/removed.#{dest}.yml")
      @removed += YAML.safe_load(File.read("data/removed.#{dest}.yml"))
    end
  end
end

Importer.new(*ARGV).run


# TODO: Incorporate
# ensure
#   driver.quit
# end

