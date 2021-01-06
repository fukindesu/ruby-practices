#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'pathname'
require 'etc'

COLUMN_SIZE = 3

def main
  opts = validated_argv_opts
  specified_path = validated_specified_path
  paths, stats = create_paths_and_stats(specified_path, opts)
  file_path_text = file_path_text_when_file_is_specified(specified_path)
  show_appropriate_paths(specified_path, paths, stats, file_path_text, opts)
end

def validated_argv_opts
  ARGV.getopts('alr')
rescue OptionParser::ParseError
  puts '[ERROR] 対応できないオプション名が含まれていました'
  exit
end

def validated_specified_path
  case ARGV.size
  when 0
    Pathname.new(Dir.getwd)
  when 1
    if FileTest.exist?(ARGV[0])
      Pathname.new(ARGV[0])
    else
      puts '[ERROR] 指定されたパスが見つかりませんでした'
      exit
    end
  else
    puts '[ERROR] パスの指定は1つだけでお願いします'
    exit
  end
end

def create_paths_and_stats(specified_path, opts)
  paths = []
  stats = { name_lengths: [], blocks_subtotals: [] }
  if specified_path.directory?
    Dir.foreach(specified_path) do |filename|
      next if !opts['a'] && filename.start_with?('.')

      path = Pathname.new(File.join(specified_path, filename))
      paths << path
      stats[:name_lengths] << filename.length
      stats[:blocks_subtotals] << path.stat.blocks
    end
    opts['r'] ? paths.sort!.reverse! : paths.sort!
  else
    paths << specified_path
  end
  [paths, stats]
end

def file_path_text_when_file_is_specified(specified_path)
  ARGV[0] if specified_path.file?
end

def show_appropriate_paths(specified_path, paths, stats, file_path_text, opts)
  if opts['l']
    paths_with_l(specified_path, paths, stats, file_path_text)
  else
    paths_without_l(specified_path, paths, stats, file_path_text)
  end
end

def paths_with_l(specified_path, paths, stats, file_path_text)
  puts "total #{stats[:blocks_subtotals].sum}" if paths.size > 1
  paths.each do |path|
    name = if specified_path.directory?
             path.basename.to_s
           else
             file_path_text
           end
    puts [
      ftype_to_chr(path.stat) + mode_to_rwx_trio(path.stat),
      path.stat.nlink.to_s,
      Etc.getpwuid(path.stat.uid).name,
      Etc.getgrgid(path.stat.gid).name,
      path.stat.size.to_s,
      path.stat.mtime.strftime('%-m %-d %H:%M'),
      name
    ].join(' ')
  end
end

def paths_without_l(specified_path, paths, stats, file_path_text)
  if specified_path.directory?
    required_row_size = (paths.size.to_f / COLUMN_SIZE).ceil
    containers = Array.new(COLUMN_SIZE) { [] }
    required_column_length = stats[:name_lengths].max
    paths.each_with_index do |path, idx|
      name = path.basename.to_s.ljust(required_column_length)
      assigned_idx = idx.div(required_row_size)
      containers[assigned_idx] << name
    end
    containers.shift.zip(*containers) { |names| puts names.join("\t") }
  else
    puts file_path_text
  end
end

def ftype_to_chr(stat)
  {
    'blockSpecial' => 'b',
    'characterSpecial' => 'c',
    'directory' => 'd',
    'link' => 'l',
    'socket' => 's',
    'fifo' => 'p',
    'file' => '-'
  }[stat.ftype]
end

def mode_to_rwx_trio(stat)
  octal = stat.mode.to_s(8)
  formats = %i[--- --x -w- -wx r-- r-x rw- rwx]
  u = octal[-3].to_i
  g = octal[-2].to_i
  o = octal[-1].to_i
  [formats[u], formats[g], formats[o]].join
end

main
