#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'

def main
  stdin_or_files, options = fetch_cli_arguments(ARGV)
  results_in_records = generate_results_in_records(stdin_or_files)
  puts display_wc(results_in_records, options)
end

def fetch_cli_arguments(argv)
  options = argv.getopts('l')
  stdin_or_files = argv
  [stdin_or_files, options]
end

def generate_results_in_records(stdin_or_files)
  if stdin?(stdin_or_files)
    text = readlines
    filename = nil
    [generate_results(text, filename)]
  else
    stdin_or_files.map do |file|
      text = IO.readlines(file)
      filename = File.basename(file)
      generate_results(text, filename)
    end
  end
end

def stdin?(stdin_or_files)
  stdin_or_files.none?
end

def generate_results(text, filename)
  {
    lines: text.size,
    words: text.map(&:split).flatten.size,
    bytes: text.join.bytesize,
    filename: filename
  }
end

def display_wc(results_in_records, options)
  records = []
  records << results_in_records.map do |results|
    [
      results[:lines].to_s.rjust(8),
      options['l'] ? nil : results[:words].to_s.rjust(8),
      options['l'] ? nil : results[:bytes].to_s.rjust(8),
      " #{results[:filename]}"
    ].join
  end
  if results_in_records.size > 1
    totals = calc_totals(results_in_records)
    records << [
      totals[:lines].to_s.rjust(8),
      options['l'] ? nil : totals[:words].to_s.rjust(8),
      options['l'] ? nil : totals[:bytes].to_s.rjust(8),
      ' total'
    ].join
  end
  records
end

def calc_totals(results_in_records)
  {
    lines: results_in_records.sum { |results| results[:lines] },
    words: results_in_records.sum { |results| results[:words] },
    bytes: results_in_records.sum { |results| results[:bytes] }
  }
end

main
