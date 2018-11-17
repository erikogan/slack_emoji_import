# frozen_string_literal: true

require 'selenium-webdriver'

module Util
  class Config
    # Browser-specific methods abstracted to their own module
    module Browser
      def log_in
        @driver ||= begin # rubocop:disable Naming/MemoizedInstanceVariableName @driver is a better name
          driver = Selenium::WebDriver.for :chrome
          driver.navigate.to "https://#{url}.slack.com/customize/emoji"

          if manual_login
            print 'wating for you to log in'
            $stdin.readline
          else
            email_input = driver.find_element(:name, 'email')
            password_input = driver.find_element(:name, 'password')

            email_input.send_keys(username)
            password_input.send_keys(password)
            email_input.submit
          end

          driver
        end
      end

      def wait
        @wait ||= Selenium::WebDriver::Wait.new(timeout: 10) # seconds
      end

      # rubocop:disable Metrics/AbcSize # These methods are essentially browser step scripts
      def remove_emoji(name)
        driver = log_in

        input = nil

        # sometimes the initial pull takes a while
        long_wait = Selenium::WebDriver::Wait.new(timeout: 60) # seconds

        # wait.until { input = driver.find_element(xpath: "//input[@aria-label = 'Search']") }
        long_wait.until { input = driver.find_element(xpath: '//input') }
        input.clear
        input.send_keys(name)

        # TODO: Figure out what to wait for for the AJAX to complete
        # wait.until { driver.execute_script('return jQuery.active == 0')}
        sleep 1

        button = nil
        wait.until { button = driver.find_element(xpath: "//button[@data-emoji-name = '#{name}']") }

        button.click

        # <button
        #     class="c-button c-button--danger c-button--medium c-dialog__go null--danger null--medium"
        #     type="button" data-qa="dialog_go">Delete Emoji</button>

        wait.until { button = driver.find_element(xpath: "//button[@data-qa = 'dialog_go']") }
        button.click

        wait.until { driver.find_element(css: '.emoji-bg-contain') }

        # Wait until it disappears, since the animation seems to screw things up otherwise
        # wait.until { driver.find_element(css: '.emoji-bg-contain').size == 0 }
      end

      def add_emoji(name, file)
        driver = log_in

        button = nil
        wait.until { button = driver.find_element(xpath: "//button[@emoji-type = 'emoji']") }
        button.click

        file_input = nil

        wait.until { file_input = driver.find_element(css: '#emojiimg') }

        name_input = driver.find_element(css: '#emojiname')
        button = driver.find_element(xpath: "//button[@data-qa = 'dialog_go']")

        file_input.send_keys(File.expand_path(file))
        name_input.send_keys(name)

        button.click

        wait.until { driver.find_element(css: '.emoji-bg-contain') }

        # Wait until it disappears, since the animation seems to screw things up otherwise
        # wait.until { driver.find_element(css: '.emoji-bg-contain').size == 0 }
      end
      # rubocop:enable Metrics/AbcSize
    end
  end
end
