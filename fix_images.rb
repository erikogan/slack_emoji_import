#!/usr/bin/env ruby

require 'byebug'

$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'util'

class Fixer
  include Util

  def run
    source_data = @source.cached_data_and_images
    # No need to cache images we are likely going to obliterate
    dest_data = @dest.cached_data['emoji']

    # byebug ; 1

    @diff.each do |name|
      puts "REMOVE: #{name}"
      @dest.remove_emoji(name)
      # byebug ;1
      puts "ADD: #{name}"
      @dest.add_emoji(name, source_data[name][:file])
      # TODO: Figure out why the JS goes screwy
      sleep 1
    end
  end

  def initialize(dest, source = nil)
    @dest = configs[dest.to_sym] || raise("no such workspace: #{dest}")
    @source = source ? configs[source.to_sym] || raise("no such workspace #{source}") : configs[:_source]
    @diff = YAML.safe_load(File.read("data/fix.#{dest}.yml"))
  end
end

Fixer.new(*ARGV).run
