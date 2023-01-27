#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require "highline"
require "./message"
require "./joplin_api"


def cli
    @cli ||= HighLine.new
end
def joplin
    raise "Please set the JOKEN env variable" if ENV["JOKEN"].nil?
    @jclient ||= JoplinApi.new(ENV["JOKEN"])
end
def prompt_to_continue?(msg = "\nContinue? ")
    if !cli.agree(msg)
        cli.say "Exiting..."
        exit 1
    end
end

if ARGV[0].nil? || ARGV[0].empty?
    abort("ERROR: Please provide a path to an mbox file as the argument.")
end



cli.say "Parsing conversations in #{ARGV[0]}..."
conversations = Message.parse_conversations!(ARGV.shift)
cli.say "Total conversations: #{conversations.size}"


ignored_labels = %w[Archived Sent Opened Important Category\ Personal]
labels = conversations.values.reduce([]) { |labels, ms| (labels + ms.map(&:gmail_labels).flatten).uniq }
labels -= ignored_labels
cli.say "\nLabels found: #{labels}"
prompt_to_continue?

cli.say "\nPlease type in the appropriate Joplin tag to use for each label...\n"
label_to_tag = {}
labels.each do |l|
    label_to_tag[l] = (cli.ask "Tag for \"#{l}\"?").downcase
end

cli.say "\nWe'll use the following mapping for labels to tags, and create tags that don't exist:"
label_to_tag.each do |l, t|
    cli.say "#{l} => #{t}"
end
prompt_to_continue?

# conversations.values.each do |messages|
#     messages.each do |m|
#         puts("===================================")
#         puts("Thread ID: #{m.gmail_thread_id}")
#         puts("Labels: #{m.gmail_labels.join(", ")}")
#         puts("From: #{m.from}")
#         puts("To: #{m.to}")
#         puts("Date: #{m.date}")
#         puts("Subject: #{m.subject}")
#         puts("Body: #{m.text_body}")
#     end
# end
