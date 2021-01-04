#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'pathname'
require 'etc'

COLUMN_SIZE = 3

# コマンドラインオプションの処理
begin
  argv_opts = ARGV.getopts('alr').freeze
rescue OptionParser::ParseError
  puts '[ERROR] 対応できないオプション名が含まれていました'
  exit
end

# 指定パスの処理
case ARGV.size
when 0
  specified_path = Pathname.new(Dir.getwd)
when 1
  if FileTest.exist?(ARGV[0])
    specified_path = Pathname.new(ARGV[0])
  else
    puts '[ERROR] 指定されたパスが見つかりませんでした'
    exit
  end
else
  puts '[ERROR] パスの指定は1つだけでお願いします'
  exit
end

# 指定パスからPathnameオブジェクトを作成
paths = []
name_length_max = 0
blocks_total = 0
if specified_path.directory?
  Dir.foreach(specified_path) do |filename|
    next if !argv_opts['a'] && filename.start_with?('.')

    path = Pathname.new(File.join(specified_path, filename))
    paths << path
    name_length_max = [name_length_max, filename.length].max
    blocks_total += path.stat.blocks
  end
  argv_opts['r'] ? paths.sort!.reverse! : paths.sort!
else
  paths << specified_path
end

# 1文字のファイルタイプに変換するメソッド
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

# rwx方式のパーミッションに変換するメソッド
def mode_to_rwx_trio(stat)
  octal = stat.mode.to_s(8)
  formats = %i[--- --x -w- -wx r-- r-x rw- rwx]
  u = octal[-3].to_i
  g = octal[-2].to_i
  o = octal[-1].to_i
  [formats[u], formats[g], formats[o]].join
end

# 出力
specified_file_path_text = ARGV[0]
if argv_opts['l']
  puts "total #{blocks_total}" if paths.size > 1
  paths.each do |path|
    name = if specified_path.directory?
             path.basename.to_s
           else
             specified_file_path_text
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
elsif specified_path.directory?
  required_row_size = (paths.size.to_f / COLUMN_SIZE).ceil
  containers = Array.new(COLUMN_SIZE) { [] }
  paths.each_with_index do |path, idx|
    name = path.basename.to_s.ljust(name_length_max)
    assigned_idx = idx.div(required_row_size)
    containers[assigned_idx] << name
  end
  containers.shift.zip(*containers) { |names| puts names.join("\t") }
else
  puts specified_file_path_text
end
