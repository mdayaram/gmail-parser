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
labels_to_tags = {}
labels.each do |l|
    labels_to_tags[l] = (cli.ask "Tag for \"#{l}\"?").downcase
end

cli.say "\nWe'll use the following mapping for labels to tags, and create tags that don't exist:"
labels_to_tags.each do |l, t|
    cli.say "#{l} => #{t}"
end
prompt_to_continue?

cli.say "\nVerify that every email/note looks correct:\n"
conversations.values.each do |messages|
    # messages.each do |m|
    #     puts("===================================")
    #     puts("Thread ID: #{m.gmail_thread_id}")
    #     puts("Labels: #{m.gmail_labels.join(", ")}")
    #     puts("From: #{m.from}")
    #     puts("To: #{m.to}")
    #     puts("Date: #{m.date}")
    #     puts("Subject: #{m.subject}")
    #     puts("Body: #{m.text_body}")
    # end
    title = messages[0].subject
    date = messages[0].date
    labels = messages.map(&:gmail_labels).flatten.uniq
    tags = labels.map { |l| labels_to_tags[l] }.compact
    body = ""
    messages.each do |m|
        if m.is_self_note?
            body += m.text_body + "\n"
        else
            body += "From: #{m.from}\nTo: #{m.to}\n\n"
            body += m.text_body
        end
    end
    body.strip!

    cli.say "\n\n====================================="
    cli.say "Title: #{title}"
    cli.say "Date: #{date}"
    cli.say "Tags: #{tags} #{tags.size > 1 ? "- !!WARNING!! - MULTIPLE TAGS!": ""}\n"
    cli.say "Body:"
    cli.say "#{body.empty? ? "NO BODY" : body}"
    prompt_to_continue?
    # TODO: Prompt to continue, upload, or skip.
    #joplin.create_note(title: title, body: body, date: date, tags: tags)
end
