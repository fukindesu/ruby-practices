#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'

# コマンドラインオプションの処理
begin
  ARGV_OPTS = ARGV.getopts('l').freeze
rescue OptionParser::ParseError
  puts '[ERROR] 対応できないオプション名が含まれていました'
  exit
end

case ARGV.size
when 0
  received_lines = readlines
  number_of_lines = received_lines.size
  number_of_words = received_lines.map(&:split).flatten.size
  number_of_bytes = received_lines.join.bytesize
  puts [
    number_of_lines.to_s.rjust(8),
    number_of_words.to_s.rjust(8),
    number_of_bytes.to_s.rjust(8)
  ].join
else
  ARGV.each do |file|
    if FileTest.file?(file)
      received_lines = IO.readlines(file)
      number_of_lines = received_lines.size
      number_of_words = received_lines.map(&:split).flatten.size
      number_of_bytes = received_lines.join.bytesize
      puts [
        number_of_lines.to_s.rjust(8),
        number_of_words.to_s.rjust(8),
        number_of_bytes.to_s.rjust(8),
        " #{file}"
      ].join
    elsif FileTest.directory?(file)
      puts "#{File.basename(__FILE__)}: #{file}: read: Is a directory"
    else
      puts "#{File.basename(__FILE__)}: #{file}: open: No such file or directory"
    end
  end
  received_lines = readlines
  number_of_lines = received_lines.size
  number_of_words = received_lines.map(&:split).flatten.size
  number_of_bytes = received_lines.join.bytesize
  puts [
    number_of_lines.to_s.rjust(8),
    number_of_words.to_s.rjust(8),
    number_of_bytes.to_s.rjust(8),
    ' total'
  ].join
end
