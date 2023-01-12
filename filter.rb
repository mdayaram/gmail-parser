#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require "pry-byebug"
require "mbox"

$stdout.sync = true

mbox = Mbox.open("gmail.mbox")
puts "Number of messages: #{mbox.length}"
binding.pry

puts "End of script."
