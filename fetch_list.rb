#!/bin/env ruby

require 'faraday'
require 'typhoeus'
require 'typhoeus/adapters/faraday'
require 'typhoeus/hydra'
require 'byebug'

Typhoeus::Config.memoize = false

BASE_URL = 'https://emoji.slack-edge.com'
HYDRA = Typhoeus::Hydra.new(:max_concurrency => 5)

conn = Faraday.new(:url => BASE_URL, :parallel_manager => HYDRA) do |builder|
  builder.request  :url_encoded
  builder.adapter  :typhoeus
end

responses = []
conn.in_parallel do
  # Will use user-defined Hydra settings: max_concurrency: 5, no memoization
  File.open(ARGV[0]) do |f|
    f.each_line do |line|
      unless line.gsub!(%r{^#{BASE_URL}(.*?)\s+}, '\1')
        warn "Skipping #{line}"
        next
      end

      match = line.match(%r{/([^/]+)/[^/]+(\.\w+)$})
      unless match
        warn "Cannot extract filename: #{line}"
        next
      end
      file = match[1,2].join('')
      responses << [file, conn.get(line)]
    end
  end
end

responses.each do |(file,resp)|
  unless resp.success?
    warn "-- Failed to download #{file}: #{resp.body}"
    next
  end

  File.write(file, resp.body)
  puts file
end
