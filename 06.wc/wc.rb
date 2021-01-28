#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'

def main
  stdin_or_files, options = fetch_cli_arguments(ARGV)
  array_with_results = fetch_array_with_results(stdin_or_files)
  puts display_wc(array_with_results, options)
end

def fetch_cli_arguments(argv)
  options = argv.getopts('l')
  stdin_or_files = argv
  [stdin_or_files, options]
end

def fetch_array_with_results(stdin_or_files)
  if stdin?(stdin_or_files)
    text = readlines
    name = nil
    [generate_results(text, name)]
  else
    files = stdin_or_files
    generate_array_with_results_for_files(files)
  end
end

def stdin?(stdin_or_files)
  stdin_or_files.none?
end

def generate_array_with_results_for_files(files)
  files.map do |file|
    text = IO.readlines(file)
    name = File.basename(file)
    generate_results(text, name)
  end
end

def generate_results(text, name)
  {
    lines: text.size,
    words: text.map(&:split).flatten.size,
    bytes: text.join.bytesize,
    name: name
  }
end

def display_wc(array_with_results, options)
  rows = array_with_results
  if rows.size >= 2
    total_results = calc_total_results(array_with_results)
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

def calc_total_results(array_with_results)
  {
    lines: array_with_results.sum { |results| results[:lines] },
    words: array_with_results.sum { |results| results[:words] },
    bytes: array_with_results.sum { |results| results[:bytes] },
    name: 'total'
  }
end

main
