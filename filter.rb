#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require "highline"
require "./message"
require "./transformation"
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
conversations = Message.parse_conversations!(ARGV[0])
cli.say "Total conversations: #{conversations.size}"

ignored_labels = %w[Archived Sent Opened Important Category\ Personal]
labels = conversations.values.reduce([]) { |labels, ms| (labels + ms.map(&:gmail_labels).flatten).uniq }.sort
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
  transformations = {
    decode_quoted_printable: false,
    compact_excess_newlines: false,
    noreply: false,
    decode_eqnewlines: false
  }

  loop do
    body_l = []
    messages.each do |m|
      text_body = Transformation.apply(m.text_body, **transformations)
      if m.is_self_note?
        body_l << text_body
      else
        body_l << "From: #{m.from}\nTo: #{m.to}\n\n" + text_body
      end
    end
    body = body_l.map(&:strip).join("\n\n--\n\n")

    cli.say "\n\n======== ENTRY #{index + 1}/#{conversations.size} ========="
    cli.say "Title: #{title}"
    cli.say "Date: #{date}"
    cli.say "Tags: #{tags}"
    cli.say "Transformations: #{transformations}\n"
    cli.say "Body:"
    puts body # cli.say has some issues printing some email bodies.

    cli.say "\n---\nWant to keep this entry?"
    response = cli.choose do |menu|
      menu.prompt = "Choose an action: "
      menu.choice(:upload)
      menu.choice(:compact_excess_newlines)
      menu.choice(:noreply)
      menu.choice(:decode_eqnewlines)
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
      cli.say "You chose to compact/uncompact excess new lines"
      transformations[:compact_excess_newlines] = !transformations[:compact_excess_newlines]
    when :decode_quote_printable
      cli.say "You chose to decode/encode quoted printable"
      transformations[:decode_quoted_printable] = !transformations[:decode_quoted_printable]
    when :noreply
      cli.say "You chose to toggle the reply quote text"
      transformations[:noreply] = !transformations[:noreply]
    when :decode_eqnewlines
      cli.say "You chose to toggle the =newlines"
      transformations[:decode_eqnewlines] = !transformations[:decode_eqnewlines]
    when :skip
      cli.say "Skipping entry #{index + 1}..."
      break
    when :quit
      cli.say "Quitting..."
      exit 1
    end
  end
end

cli.say "\n\n=============================================\n\nDone with all entries!"
if labels_to_tags.size > 1
  cli.say "\n\nWARNING: Multiple tags! Don't forget to remove ALL labels from these email!"
end
delete_file = (cli.ask "Delete mbox file? (default is no) ").strip.downcase
if delete_file[0] == "y" || delete_file[0] == "1"
  File.delete(ARGV[0])
  cli.say "Deleted file #{ARGV[0]}"
end
