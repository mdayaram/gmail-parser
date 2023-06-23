class Transformation
  def initialize(text)
    @raw_text = text
  end

  def to_s
    @raw_text
  end

  def self.apply(text,
    decode_quoted_printable: false,
    compact_excess_newlines: false,
    noreply: false,
    decode_eqnewlines: false)

    return text if text.nil? || text.empty?
    text = text.gsub("\r", "")

    t = self.new(text)
    if decode_eqnewlines
      t = self.new t.decode_eqnewlines
    end
    if noreply
      t = self.new t.noreply
    end
    if compact_excess_newlines
      t = self.new t.compact_excess_newlines
    end
    if decode_quoted_printable
      t = self.new t.decode_quoted_printable
    end

    t.to_s
  end

  def decode_quoted_printable
    @raw_text.unpack("M").first.encode("utf-8", "iso-8859-1")
  end

  def compact_excess_newlines
    @raw_text.gsub("\r", "").gsub(/(?<!\s)\n(?!\s)/, " ")
  end

  def noreply
    lines = @raw_text.split("\n")
    has_reply = false
    while lines && lines[-1].start_with?(">") do
      lines.pop
      has_reply = true
    end

    # Remove the "On <date> <person> wrote:"
    if has_reply && lines[-1].strip.empty? && lines[-2].start_with?("On ")
      lines.pop
      lines.pop
    end

    lines.join("\n")
  end

  def decode_eqnewlines
    lines = @raw_text.split("\n")
    i = lines.size - 1
    while i > 0 do
      if lines[i-1].end_with?("=")
        # get rid of the = sign on the previous line and join with next line.
        lines[i-1] = lines[i-1][0..-2] + lines[i]
        lines.delete_at(i)
      end
      i -= 1
    end

    lines.join("\n")
  end
end
