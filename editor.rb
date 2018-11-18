# frozen_string_literal: true

require 'sinatra/base'
require 'pathname'

require 'json'
require 'yaml'

require 'byebug'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'lib')
require 'util'

class Editor < Sinatra::Base
  set(:root, File.dirname(__FILE__))

  get '/' do
    data = self.class.sort ? self.class.source_data.sort_by { |k, _v| k } : self.class.source_data

    @files = data.each_with_object({}) do |(name, url), hash|
      name = name.to_s

      disabled = self.class.disabled_global.include?(name)
      disabled_dest = self.class.disabled_dest.include?(name)
      # Short cut when just trying to pare down disables
      # next if url =~ /^alias/ || self.class.dest_data.key?(name) || disabled || disabled_dest

      base = url =~ /alias:(.*)/ ? { alias: Regexp.last_match(1) } : { url: url }
      hash[name] = base.merge(
        name: name,
        disabled: disabled,
        dest_disabled: disabled_dest
      )
    end

    puts @files.to_yaml
    @dest_name = self.class.dest.name

    haml :index, format: :html5
  end

  post '/' do
    params.delete('submit')
    dest = params.delete('dest_name')

    results = params.group_by { |_k, v| v }

    [%w[disabled disabled], ["disabled.#{dest}", dest]].each do |(file, value)|
      next unless results[value]

      path = "data/#{file}.yml"
      old_values = File.exist?(path) ? YAML.safe_load(File.read(path)) : []
      new_values = results[value].map { |(k, _v)| k }

      File.write("data/#{file}.yml", (old_values | new_values).sort.to_yaml)
    end

    redirect '/'
  end

  get '/diff' do
    byebug;1
    @dest_name = self.class.dest.name
    diff = YAML.safe_load(File.read("data/diff.#{@dest_name}.yml")).sort

    fix = begin
            Hash[YAML.safe_load(File.read("data/fix.#{@dest_name}.yml")).map { |x| [x, true] }]
          rescue StandardError
            {}
          end

    @files = diff.each_with_object({}) do |name, hash|
      hash[name] = [self.class.source_data[name], self.class.dest_data[name], fix[name]]
    end

    haml :diff, format: :html5
  end

  post '/diff' do
    byebug;1
    dest = params.delete('dest_name')
    files = params.keys.reject { |k| k == 'submit' }
    File.write("data/fix.#{dest}.yml", files.to_yaml)

    redirect '/diff'
  end

  class << self
    include Util

    attr_accessor :sort, :source, :source_data, :dest, :dest_data, :disabled_global, :disabled_dest

    def destination=(dest)
      raise 'Usage: editor.rb [--sort] <destination> [source]' unless dest

      @dest = configs[dest.to_sym] || raise("no such workspace: #{dest}")
      @dest_data = @dest.cached_data['emoji']
      self.disabled = dest
    end

    def source=(source)
      @source = source ? configs[source.to_sym] || raise("no such workspace #{source}") : configs[:_source]
      @source_data = @source.cached_data['emoji']
    end

    def disabled=(dest)
      @disabled_global = File.exist?('data/disabled.yml') ? YAML.safe_load(File.read('data/disabled.yml')) : []
      dest_file = "data/disabled.#{dest}.yml"
      @disabled_dest = File.exist?(dest_file) ? YAML.safe_load(File.read(dest_file)) : []
    end
  end
end

if $PROGRAM_NAME == __FILE__
  if ARGV[0] == '--sort'
    Editor.sort = true
    ARGV.shift
  end

  Editor.destination = ARGV[0]
  Editor.source = ARGV[1]

  Editor.run!
end
