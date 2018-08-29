#!/usr/bin/env ruby

require 'json'
require 'yaml'
require 'byebug'

$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'util'

class Fixer
  include Util

  def run
    source_data = @source.cached_data['emoji']
    dest_data = @dest.cached_data['emoji']

    source_data.each do |name, link|
      next unless link =~ /alias:(.*)/
      next unless dest_data.key?(name)
      next if dest_data[name] == link
      puts "#{name} : #{dest_data[name]} : #{link}"
    end
  end

  def initialize(dest, source = nil)
    @dest = configs[dest.to_sym] || raise("no such workspace: #{dest}")
    @source = source ? config[source.to_sym] || raise("no such workspace #{source}") : configs[:_source]
  end
end

Fixer.new(*ARGV).run
