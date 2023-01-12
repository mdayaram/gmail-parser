#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require "mbox"

$stdout.sync = true

mbox = Mbox.open("gmail.mbox")
puts "Number of messages: #{mbox.length}"
