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
def decode_quoted_printable(text)
  text.unpack("M").first.encode("utf-8", "iso-8859-1")
end
def compact_excess_newlines(text)
  text.gsub("\r", "").gsub(/(?<!\s)\n(?!\s)/, " ")
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

cli.say "\nPlease type in the appropriate Joplin tag to use for each label..."
cli.say "Leave blank to use the suggested label."
cli.say "Type \"skip\" to ignore the label."
labels_to_tags = {}
ignored_labels = []
labels.each do |l|
  suggested = l.gsub("People/", "").strip.downcase
  tag = (cli.ask "\nTag for \"#{l}\" - (suggestion: #{suggested})?").strip.downcase
  if tag == "skip"
    ignored_labels << l
  elsif !tag.empty?
    labels_to_tags[l] = tag
  else
    labels_to_tags[l] = suggested
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
  body_l = []
  messages.each do |m|
    if m.is_self_note?
      body_l << m.text_body
    else
      body_l << "From: #{m.from}\nTo: #{m.to}\n\n" + m.text_body
    end
  end
  body = body_l.map(&:strip).join("\n\n--\n\n")

  cli.say "\n\n======== ENTRY #{index + 1}/#{conversations.size} ========="
  cli.say "Title: #{title}"
  cli.say "Date: #{date}"
  cli.say "Tags: #{tags} #{tags.size > 1 ? "- !!WARNING!! - MULTIPLE TAGS!": ""}\n"
  cli.say "Body:"
  puts body # cli.say has some issues printing some email bodies.

  loop do
    cli.say "\n---\nWant to keep this entry?"
    response = cli.choose do |menu|
      menu.prompt = "Choose an action: "
      menu.choice(:upload)
      menu.choice(:compact_excess_newlines)
      menu.choice(:decode_quote_printable)
      menu.choice(:skip)
      menu.choice(:quit)
    end

    case response
    when :upload
      cli.say "You chose to upload, beginning upload process..."
      joplin.create_note(title: title, body: body, date: date, tags: tags)
      cli.say "...done!"
      break
    when :compact_excess_newlines
      cli.say "You chose to compact excess new lines"
      cli.say "Here's what that looks like:"
      body = compact_excess_newlines(body)
      puts "\n" + body
    when :decode_quote_printable
      cli.say "You chose to decode quoted printable"
      cli.say "Here's what that looks like:"
      body = decode_quoted_printable(body)
      puts "\n" + body
    when :skip
      cli.say "Skipping entry #{index + 1}..."
      break
    when :quit
      cli.say "Quitting..."
      exit 1
    end
  end
end

cli.say "\n\nDone with all entries!"
cli.say "TODO: Don't forget to remove ALL labels from these email!"
