# frozen_string_literal: true

require 'sinatra'
require 'pathname'

PUBLIC_FOLDER = 'images'

set(:root, File.dirname(__FILE__))
set(:public_folder, proc { File.join(root, PUBLIC_FOLDER) })

get '/' do
  files = Dir["#{PUBLIC_FOLDER}/*.{png,gif,jpg}"].sort
  @files = files.map do |f|
    base = f.gsub(%r{.*/}, '')
    name = base.gsub(/\.\w+$/, '')
    {
      base: base,
      name: name,
      url: base
    }
  end
  haml :index, format: :html5
end

post '/' do
  files = params.keys.reject { |k| k == 'submit' }
  files.each do |f|
    File.rename("#{PUBLIC_FOLDER}/#{f}", "#{PUBLIC_FOLDER}/removed/#{f}")
  end

  redirect '/'
end
