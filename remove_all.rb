#!/usr/bin/env ruby
# frozen_string_literal: true

require 'byebug'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'lib')
require 'util'

class Fixer
  include Util

  def run(*emoticons)
    # Loop over emoticons first to help JS settle out
    emoticons.each do |emoticon|
      puts "============== #{emoticon}"
      configs.each do |name, config|
        next if name == :_source || config == configs[:_source]

        unless config.cached_data['emoji'][emoticon]
          puts "Not in #{name}, skipping"
          next
        end
        begin
          config.remove_emoji(emoticons)
        rescue Selenium::WebDriver::Error::TimeOutError
          puts "error on #{name}, moving on"
          next
        end
        puts name
        sleep 1
      end
    end
  end
end

Fixer.new.run(*ARGV)
