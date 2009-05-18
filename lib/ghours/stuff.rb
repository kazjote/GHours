require 'net/http'

require 'rubygems'
require 'highline/import'
require 'activesupport'

class String
  def to_time
    matches = /([\d]{4})-([\d]{2})-([\d]{2})T([\d]{2}):([\d]{2}):([\d]{2}).*/.match(to_s)
    Time.mktime(*matches[1..6])
  end
end

class Time
  def this_week?
    self > Time.now.monday
  end
end

module Net
  class HTTP
    def fetch(path, headers, limit = 10)
      # You should choose better exception.
      raise ArgumentError, 'HTTP redirect too deep' if limit == 0

      response, body = get(path, headers)
      case response
      when Net::HTTPSuccess
        body
      when Net::HTTPRedirection
        fetch(response['location'], headers, limit - 1)
      else
        response.error!
      end
    end
  end
end


module GHours

  class ExitReason < Exception
  end

  class Configuration

    def found?
      File.exists?(config_path)
    end

    def init_new
      file = File.new(config_path, "w")
      file.write(UI.ask_for_email)
      file.close
    end

    def credentials
      file = File.new(config_path, "r")
      [file.readlines.first, UI.password]
    end

    def config_path
      File.join(ENV["HOME"], ".ghours")
    end

  end

  class Connection

    def initialize(email, pass)
      @gdata = Googlecalendar::GData.new
      @token = @gdata.login(email, pass)
    end

    def events calendar_name
      @gdata.get_calendars
      headers = {"Authorization" => "GoogleLogin auth=#{@token}"}
      calendar = @gdata.find_calendar(calendar_name)
      raise ExitReason.new("Calendar not found :(") unless calendar

      time_format = "%Y-%m-%dT00:00:00"
      query = ["start-min=", Time.now.utc.beginning_of_month.strftime(time_format)].join
      Net::HTTP.new("www.google.com").fetch([calendar.url, query].join("?"), headers)
    end

  end

  module UI
    def self.print_hours(in_week, in_month)
      puts "In this week : #{in_week}"
      puts "        month: #{in_month}"
    end

    def self.ask_for_email
      ask("Enter your email address used to login to your calendar:")
    end

    def self.password
      ask("Enter your password:") { |q| q.echo = false }
    end
  end
end

