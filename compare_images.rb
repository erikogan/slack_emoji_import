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
    source_data = @source.cached_data_and_images
    dest_data = @dest.cached_data_and_images
    byebug; 1
    diffs = []

    dest_data.each do |name, data|
      next if data[:alias]

      source = source_data[name]
      next unless source

      source = source_data[source[:alias]] while source.key?(:alias)

      if data[:md5] == source[:md5]
        puts "#{name} : same"
        next
      end

      diffs << name
      puts "#{name} : DIFFERENT"
    end

    puts diffs.to_yaml
    File.write("data/diff.#{@dest.name}.yml", diffs.to_yaml)
  end

  def initialize(dest, source = nil)
    @dest = configs[dest.to_sym] || raise("no such workspace: #{dest}")
    @source = source ? configs[source.to_sym] || raise("no such workspace #{source}") : configs[:_source]
  end
end

Fixer.new(*ARGV).run
