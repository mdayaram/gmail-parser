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

# Initialize joplin client.
joplin


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
ignored_labels = []
labels.each do |l|
    tag = (cli.ask "Tag for \"#{l}\"?").downcase
    if !tag.empty?
      labels_to_tags[l] = tag
    else
      ignored_labels << l
    end
end

cli.say "\nWe'll use the following mapping for labels to tags (note: DNE means the tag does not exist and would be created):"
labels_to_tags.each do |l, t|
    current_tag = joplin.find_tag(t) || {"id" => "DNE"}
    cli.say "#{l} => #{t} - ID: #{current_tag["id"]}"
end
ignored_labels.each do |l|
  cli.say "#{l} => IGNORED"
end
prompt_to_continue?

cli.say "\nVerify that every email/note looks correct:\n"
conversations.values.each_with_index do |messages, index|
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

    cli.say "\n\n======== ENTRY #{index + 1}/#{conversations.size} ========="
    cli.say "Title: #{title}"
    cli.say "Date: #{date}"
    cli.say "Tags: #{tags} #{tags.size > 1 ? "- !!WARNING!! - MULTIPLE TAGS!": ""}\n"
    cli.say "Body:"
    cli.say "#{body.empty? ? "NO BODY" : body}"

    cli.say "\n---\nWant to keep this entry?"
    response = cli.choose do |menu|
        menu.prompt = "Choose an action: "
        menu.choice(:upload)
        menu.choice(:skip)
        menu.choice(:quit)
    end

    case response
    when :upload
        cli.say "You chose to upload, beginning upload process..."
        joplin.create_note(title: title, body: body, date: date, tags: tags)
        cli.say "...done!"
    when :skip
        cli.say "Skipping entry #{index + 1}..."
    when :quit
        cli.say "Quitting..."
        exit 1
    end
end

cli.say "\n\nDone with all entries!"
cli.say "TODO: Don't forget to remove ALL labels from these email!"