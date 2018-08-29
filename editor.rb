# frozen_string_literal: true

require 'sinatra'
require 'pathname'

require 'json'
require 'yaml'

require 'byebug'

set(:root, File.dirname(__FILE__))

get '/' do
  #####
  ##### TODO: Use UTIL to get the source data
  #####
  emoji = JSON.parse(File.read('data/raw/change.json'))['emoji']
  slackers = JSON.parse(File.read('data/raw/slackers.json'))['emoji']
  removed = YAML.safe_load(File.read('data/removed.yml'))
  home = YAML.safe_load(File.read('data/removed.home.yml'))

  @files = emoji.each_with_object({}) do |(name, url), hash|
    name = name.to_s
    disabled = removed.include?(name)
    disabled_home = home.include?(name)
    next if url =~/^alias/ || slackers.key?(name) || disabled || disabled_home

    base = url =~ /alias:(.*)/ ? {alias: $1} : {url: url}
    hash[name] = base.merge(
      name: name,
      disabled: disabled,
      home: disabled_home,
    )
  end

  puts @files.to_yaml

  haml :index, format: :html5
end

post '/' do
  params.delete('submit')

  results = params.group_by {|k,v| v}

  [['removed', 'disabled'], ['removed.home', 'home']].each do |(file, value)|
    next unless results[value]
    old_values = YAML.safe_load(File.read("data/#{file}.yml"))
    new_values = results[value].map {|(k, v)| k}

    File.write("data/#{file}.yml", (old_values | new_values).sort.to_yaml)
  end

  redirect '/'
end

get '/diff' do
  diff = YAML.safe_load(File.read('data/diff.home.yml')).sort
  emoji = JSON.parse(File.read('data/raw/change.json'))['emoji']
  home = JSON.parse(File.read('data/raw/home.json'))['emoji']

  fix = Hash[YAML.safe_load(File.read('data/fix.home.yml')).map {|x| [x, true]}] rescue {}

  @files = diff.each_with_object({}) do |name, hash|
    hash[name] = [emoji[name], home[name], fix[name]]
  end

  haml :diff, format: :html5
end

post '/diff' do
  files = params.keys.reject { |k| k == 'submit' }
  File.write('data/fix.home.yml', files.to_yaml)

  redirect '/diff'
end
