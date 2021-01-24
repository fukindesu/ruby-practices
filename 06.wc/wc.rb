#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'

def main
  stdin_or_files, options = fetch_cli_arguments(ARGV)
  records_with_results = generate_records_with_results(stdin_or_files)
  puts display_wc(records_with_results, options)
end

def fetch_cli_arguments(argv)
  options = argv.getopts('l')
  stdin_or_files = argv
  [stdin_or_files, options]
end

def generate_records_with_results(stdin_or_files)
  if stdin?(stdin_or_files)
    text = readlines
    name = nil
    [generate_results(text, name)]
  else
    stdin_or_files.map do |file|
      text = IO.readlines(file)
      name = File.basename(file)
      generate_results(text, name)
    end
  end
end

def stdin?(stdin_or_files)
  stdin_or_files.none?
end

def generate_results(text, name)
  {
    lines: text.size,
    words: text.map(&:split).flatten.size,
    bytes: text.join.bytesize,
    name: name
  }
end

def display_wc(records_with_results, options)
  rows = records_with_results
  if rows.size >= 2
    total_results = generate_total_results(records_with_results)
    rows << total_results
  end
  rows.map do |row|
    [
      row[:lines].to_s.rjust(8),
      options['l'] ? nil : row[:words].to_s.rjust(7),
      options['l'] ? nil : row[:bytes].to_s.rjust(7),
      row[:name]
    ].compact.join(' ')
  end
end

def generate_total_results(records_with_results)
  {
    lines: records_with_results.sum { |results| results[:lines] },
    words: records_with_results.sum { |results| results[:words] },
    bytes: records_with_results.sum { |results| results[:bytes] },
    name: 'total'
  }
end

main
