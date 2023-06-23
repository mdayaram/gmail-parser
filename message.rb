#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require "mbox"
require "date"
require "pry-byebug"

class Message
  attr_reader :gmail_thread_id, :gmail_labels
  attr_reader :from, :to, :date, :subject
  attr_reader :text_body, :html_body

  def initialize(mbox_message)
    @gmail_thread_id = mbox_message.headers["X-Gm-Thrid"]
    @gmail_labels = mbox_message.headers["X-Gmail-Labels"]&.split(",")&.map(&:strip)
    @from = mbox_message.headers["From"]
    @to = mbox_message.headers["To"]
    @date = parse_date(mbox_message.headers["Date"])
    @subject = mbox_message.headers["Subject"]
    @text_body = ""
    @html_body = ""

    mbox_message.content.each do |c|
      if c.headers[:content_type].mime == "text/plain"
        @text_body += c.content
      elsif c.headers[:content_type].mime == "text/html"
        @html_body += c.content
      else
        # ignore other content types, probably just metadata.
        # e.g. "multipart/alternative", "multipart/mixed"
      end
    end
  end

  def is_self_note?
    emails = ["m@noj.cc", "i.am.noj@gmail.com", "noj@alumni.cmu.edu", "mdayaram@andrew.cmu.edu", "noj@squareup.com", "noj@moovweb.com"]
    emails.any? { |e| from.include?(e) } && emails.any? { |e| to.include?(e) }
  end

  def parse_date(date_str)
    return date_str if date_str.nil? || date_str.empty?

    possible_formats = [
      "%a, %e %b %Y %H:%M:%S %z", # Mon, 7 Dec 2015 00:28:51 -0800
      "%e %b %Y %H:%M:%S %z",     # 7 Dec 2015 00:28:51 -0800
    ]

    possible_formats.each do |format|
      begin
        return DateTime.strptime(date_str, format)
      rescue => _
      end
    end

    raise "Could not parse date: #{date_str}"
  end

  # Returns a hash of...
  # { conversation_thread_id => [messages...] }
  def self.parse_conversations!(mbox_filename)
    conversations = {}
    mb = Mbox.open(mbox_filename)
    mb.each do |m|
      message = Message.new(m)
      conversations[message.gmail_thread_id] ||= []
      conversations[message.gmail_thread_id] << message
    end
    conversations.values.each { |c| c.sort_by!(&:date) }
    conversations
  end
end
