#!/usr/bin/env ruby

require "selenium-webdriver"
require 'byebug'

# JQuery to grab all the images from the page:
# el = $('td[headers="custom_emoji_image"]').filter(() => { return $(this).siblings('td[headers="custom_emoji_type"]:contains("Image")').length > 0})
# save = []
# $.map(el, (s) => {save.push($(s).data('original'))} ))
# JSON.stringify(save)

url = 'https://<YOUR_GROUP>.slack.com/customize/emoji'
EMAIL = 'YOUR EMAIL'
PASSWORD = 'YOUR PASSWORD'

driver = Selenium::WebDriver.for :chrome

def file_to_name(file)
  file.gsub(%r{(?:^.*/)?(.*)\.\w+$}, '\1')
end

begin
  driver.navigate.to url

  email = driver.find_element(:name, 'email')
  password = driver.find_element(:name, 'password')

  email.send_keys(EMAIL)
  password.send_keys(PASSWORD)
  email.submit

  wait = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds
  table = nil
  wait.until { table = driver.find_element(:id => "custom_emoji") }

  names = table.find_elements(:css, '.emoji_row > td:nth-of-type(2)')
  names.map! {|n| n.text.gsub(/:([^:]+):/, '\1')}

  files = Dir['images/*.{jpg,png,gif}'].reject {|f| names.include?(file_to_name(f))}.sort

  files.each do |f|
    name_field = nil
    wait.until {  name_field = driver.find_element(:id, 'emojiname') }

    name_field = driver.find_element(:id, 'emojiname')
    file = driver.find_element(:id, 'emojiimg')
    # No useful way to find it directly?
    submit = driver.find_element(:css, '#addemoji .btn_primary')
    file.send_keys(File.expand_path(f))
    name_field.clear()
    name = file_to_name(f)
    name_field.send_keys(name)
    puts name
    submit.click
  end
ensure
  driver.quit
end
