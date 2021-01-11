#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'pathname'
require 'etc'

COLUMN_SIZE = 3

def main
  argv_path, argv_opts = fetch_cli_arguments(ARGV)
  pathnames = create_pathnames(argv_path, argv_opts)
  puts display_list(pathnames, argv_path, argv_opts)
end

def fetch_cli_arguments(argv)
  argv_opts = argv.getopts('alr')
  raise 'パスの指定は1つだけでお願いします' if argv.size > 1

  argv_path = argv.empty? ? Pathname.new(Dir.getwd) : Pathname.new(argv[0])
  [argv_path, argv_opts]
end

def create_pathnames(argv_path, argv_opts)
  if argv_path.directory?
    unsorted_pathnames = []
    Dir.foreach(argv_path) do |filename|
      next if !argv_opts['a'] && filename.start_with?('.')

      pathname = Pathname.new(File.join(argv_path, filename))
      unsorted_pathnames << pathname
    end
    pathnames = if argv_opts['r']
                  unsorted_pathnames.sort.reverse
                else
                  unsorted_pathnames.sort
                end
  elsif argv_path.file?
    pathnames = [argv_path]
  end
  pathnames
end

def display_list(pathnames, argv_path, argv_opts)
  if argv_opts['l']
    display_list_with_l_opt(pathnames, argv_path)
  else
    display_list_without_l_opt(pathnames, argv_path)
  end
end

def display_list_with_l_opt(pathnames, argv_path)
  rows = []
  rows << "total #{calc_blocks_total(pathnames)}" if argv_path.directory?
  pathnames.each do |pathname|
    stat = pathname.stat
    row = [
      ftype_to_chr(stat) + mode_to_rwx_trio(stat),
      stat.nlink.to_s,
      Etc.getpwuid(stat.uid).name,
      Etc.getgrgid(stat.gid).name,
      stat.size.to_s,
      stat.mtime.strftime('%-m %-d %H:%M'),
      name_for_display(pathname, argv_path)
    ].join(' ')
    rows << row
  end
  rows
end

def calc_blocks_total(pathnames)
  pathnames.map { |pathname| pathname.stat.blocks }.sum
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

def name_for_display(pathname, argv_path)
  if argv_path.directory?
    pathname.basename.to_s
  elsif argv_path.file?
    specified_file_path_text(argv_path)
  end
end

def specified_file_path_text(argv_path)
  ARGV[0] if argv_path.file?
end

def display_list_without_l_opt(pathnames, argv_path)
  rows = []
  if argv_path.directory?
    containers = Array.new(COLUMN_SIZE) { [] }
    row_size = (pathnames.size.to_f / COLUMN_SIZE).ceil
    pathnames.each_with_index do |pathname, idx|
      name_length_max = calc_name_length_max(pathnames)
      name = pathname.basename.to_s.ljust(name_length_max)
      assigned_idx = idx / row_size
      containers[assigned_idx] << name
    end
    containers.shift.zip(*containers) { |names| rows << names.join("\t") }
  elsif argv_path.file?
    rows << specified_file_path_text(argv_path)
  end
  rows
end

def calc_name_length_max(pathnames)
  pathnames.map { |pathname| pathname.basename.to_s.length }.max
end

main
