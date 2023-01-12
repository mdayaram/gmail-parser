#!/usr/bin/env ruby

$stdout.sync = true
label_filter = 'people'
current_message = []

prev_newline = true
save_message = false
num_messages = 0
saved_num_messages = 0

outfile = File.open(label_filter + ".mbox", "a")

puts "opening file"
File.open("gmail.mbox") do |f|
	puts "file open, going through lines"

	f.each_line.with_index do |line, lineno|
		line.strip!
		if line.start_with?("From:") && prev_newline
			# start of a new message
			puts "Processed ##{num_messages}"
			puts "Saved ##{saved_num_messages}"
			num_messages += 1
			if save_message
				saved_num_messages += 1
				current_message.each do |l|
					outfile.write(l + "\n")
					outfile.flush
				end
				exit 1
			end
			current_message = []
			save_message = false
			GC.start
		end


		if line.start_with?("X-Gmail-Labels:")
			if line.downcase.include?(label_filter)
				save_message = true
			end
		end

		current_message << line
		prev_newline = line.empty?
	end
end
