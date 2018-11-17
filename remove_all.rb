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
        next if source?(config)
        next unless check_presence(emoticon, config)
        next unless do_remove(emoticon, config)

        puts name
        sleep 1
      end
    end
  end

  def source?(config)
    config.name == :_source || config == configs[:_source]
  end

  def check_presence(emoticon, config)
    present = !config.cached_data['emoji'][emoticon].nil?
    puts "Not in #{config.name}, skipping" unless present
    present
  end

  def do_remove(emoticon, config)
    begin
      config.remove_emoji(emoticon)
    rescue Selenium::WebDriver::Error::TimeOutError
      puts "error on #{config.name}, moving on"
      return false
    end

    true
  end
end

Fixer.new.run(*ARGV)
