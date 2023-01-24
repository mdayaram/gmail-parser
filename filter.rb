#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require "./message"


if ARGV[0].nil? || ARGV[0].empty?
    abort("ERROR: Please provide a path to an mbox file as the argument.")
end

conversations = Message.parse_conversations!(ARGV.shift)
conversations.values.each do |messages|
    messages.each do |m|
        puts("===================================")
        puts("Thread ID: #{m.gmail_thread_id}")
        puts("Labels: #{m.gmail_labels.join(", ")}")
        puts("From: #{m.from}")
        puts("To: #{m.to}")
        puts("Date: #{m.date}")
        puts("Subject: #{m.subject}")
        puts("Body: #{m.text_body}")
    end
end
puts ""
puts "Total emails: #{conversations.size}"
