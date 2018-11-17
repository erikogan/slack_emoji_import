#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'yaml'
require 'digest'

require 'byebug'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'lib')
require 'util'

class Fixer
  include Util

  def run
    diffs = []

    @dest_data.each do |name, data|
      if diff_item(name, data)
        diffs << name
        puts "#{name} : DIFFERENT"
      else
        puts "#{name} : same"
      end
    end

    write_data(diffs)
  end

  def diff_item(name, data)
    return false if data[:alias]

    source = source_for_name(name)
    return false unless source

    if data[:md5] == source[:md5]
      puts "#{name} : same"
      return false
    end

    true
  end

  def source_for_name(name)
    source = @source_data[name]
    return nil unless source

    source = @source_data[source[:alias]] while source.key?(:alias)
    source
  end

  def write_data(data)
    yaml = data.to_yaml
    puts yaml
    File.write("data/diff.#{@dest.name}.yml", yaml)
  end

  def initialize(dest, source = nil)
    @dest = configs[dest.to_sym] || raise("no such workspace: #{dest}")
    @source = source ? configs[source.to_sym] || raise("no such workspace #{source}") : configs[:_source]

    @dest_data = @dest.cached_data_and_images
    @source_data = @source.cached_data_and_images
  end
end

Fixer.new(*ARGV).run
