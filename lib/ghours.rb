$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require "ghours/stuff"

require 'rubygems'
require 'googlecalendar'
require 'activesupport'
require 'rexml/document'

module GHours
  VERSION = '0.0.1'

  def self.process(argv)
    if(argv.empty?)
      raise ExitReason.new("USAGE: ghours <calendar_name>")
    end

    config = Configuration.new
    config.init_new unless config.found?

    email, pass = config.credentials

    connection = Connection.new(email, pass)
    in_week, in_month = count_hours(connection.events(argv[0]))
    UI.print_hours(in_week, in_month)
  rescue GHours::ExitReason => ex
    puts ex.message
    exit 1
  end

  def self.count_hours events
    doc = REXML::Document.new(events)

    done = Hash.new(0.0)
    doc.elements.each("*/entry/gd:when") do |time_elem|
      diff = (start = time_elem.attributes["endTime"].to_time) -
        time_elem.attributes["startTime"].to_time
      diff = diff / 60.0 / 60.0
      done[:week] += diff if start.this_week?
      done[:month] += diff
    end

    [done[:week], done[:month]]
  end
end

