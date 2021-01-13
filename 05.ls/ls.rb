#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'pathname'
require 'etc'

COLUMN_SIZE = 3

FILE_TYPE_REFERENCE_TABLE = {
  'blockSpecial' => 'b',
  'characterSpecial' => 'c',
  'directory' => 'd',
  'link' => 'l',
  'socket' => 's',
  'fifo' => 'p',
  'file' => '-'
}.freeze

RWX_FORMAT_PERMISSIONS = %w[--- --x -w- -wx r-- r-x rw- rwx].freeze

def main
  argv_path, argv_opts = fetch_cli_arguments(ARGV)
  pathnames = create_pathnames(argv_path, argv_opts)
  puts display_list(pathnames, argv_path, argv_opts)
end

def fetch_cli_arguments(argv)
  argv_opts = argv.getopts('alr')
  raise 'パスの指定は1つだけでお願いします' if argv.size > 1

  argv_path = Pathname.new(argv[0] || Dir.getwd)
  [argv_path, argv_opts]
end

def create_pathnames(argv_path, argv_opts)
  if argv_path.directory?
    create_pathnames_for_directory(argv_path, argv_opts)
  else
    [argv_path]
  end
end

def create_pathnames_for_directory(argv_path, argv_opts)
  flags = argv_opts['a'] ? File::FNM_DOTMATCH : 0
  unsorted_pathnames =
    Dir.glob('*', flags, base: argv_path).map do |filename|
      Pathname.new(File.join(argv_path, filename))
    end
  argv_opts['r'] ? unsorted_pathnames.sort.reverse : unsorted_pathnames.sort
end

def display_list(pathnames, argv_path, argv_opts)
  if argv_opts['l']
    display_list_with_l_opt(pathnames, argv_path)
  else
    display_list_without_l_opt(pathnames, argv_path)
  end
end

def display_list_with_l_opt(pathnames, argv_path)
  max_lengths = calc_stat_max_lengths(pathnames)
  total_row = "total #{calc_blocks_total(pathnames)}" if argv_path.directory?
  rows = pathnames.map do |pathname|
    stat = pathname.stat
    [
      "#{FILE_TYPE_REFERENCE_TABLE[stat.ftype]}#{mode_to_rwx_trio(stat)} ",
      stat.nlink.to_s.rjust(max_lengths[:nlink]),
      Etc.getpwuid(stat.uid).name.ljust(max_lengths[:user]),
      Etc.getgrgid(stat.gid).name.center(max_lengths[:group] + 2),
      stat.size.to_s.rjust(max_lengths[:size]),
      stat.mtime.strftime('%-m').rjust(2),
      stat.mtime.strftime('%e'),
      stat.mtime.strftime('%H:%M'),
      pathname.basename.to_s
    ].join(' ')
  end
  [total_row, *rows].compact
end

def calc_stat_max_lengths(pathnames)
  # FIXME: やや強引に処理している気もしています…
  max_lengths = { nlink: 0, user: 0, group: 0, size: 0 }
  pathnames.each do |pathname|
    stat = pathname.stat
    max_lengths[:nlink] = [max_lengths[:nlink], stat.nlink.to_s.length].max
    max_lengths[:user] = [max_lengths[:user], Etc.getpwuid(stat.uid).name.length].max
    max_lengths[:group] = [max_lengths[:group], Etc.getgrgid(stat.gid).name.length].max
    max_lengths[:size] = [max_lengths[:size], stat.size.to_s.length].max
  end
  max_lengths
end

def calc_blocks_total(pathnames)
  pathnames.sum { |pathname| pathname.stat.blocks }
end

def mode_to_rwx_trio(stat)
  octal_mode_text = stat.mode.to_s(8)[-3, 3]
  octal_mode_text.chars.map { |char| RWX_FORMAT_PERMISSIONS[char.to_i] }.join
end

def display_list_without_l_opt(pathnames, argv_path)
  if argv_path.directory?
    containers = Array.new(COLUMN_SIZE) { [] }
    row_size = (pathnames.size.to_f / COLUMN_SIZE).ceil
    pathnames.each_with_index do |pathname, idx|
      name = pathname.basename.to_s.ljust(calc_basename_length_max(pathnames))
      assigned_idx = idx / row_size
      containers[assigned_idx] << name
    end
    containers.shift.zip(*containers).map { |names| names.join("\t") }
  else
    [argv_path.basename.to_s]
  end
end

def calc_basename_length_max(pathnames)
  pathnames.map { |pathname| pathname.basename.to_s.length }.max
end

main
