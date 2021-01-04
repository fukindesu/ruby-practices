#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'pathname'
require 'etc'

# コマンドラインオプションの処理
begin
  ARGV_OPTS = ARGV.getopts('alr').freeze
rescue OptionParser::ParseError
  puts '[ERROR] 対応できないオプション名が含まれていました'
  exit
end

# 指定パスの処理
case ARGV.size
when 0
  SPECIFIED_PATH = Pathname.new(Dir.getwd)
when 1
  if FileTest.exist?(ARGV[0])
    SPECIFIED_PATH = Pathname.new(ARGV[0])
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
if SPECIFIED_PATH.directory?
  Dir.foreach(SPECIFIED_PATH) do |filename|
    next if !ARGV_OPTS['a'] && filename.start_with?('.')

    path = Pathname.new(File.join(SPECIFIED_PATH, filename))
    paths << path
    name_length_max = [name_length_max, filename.length].max
    blocks_total += path.stat.blocks
  end
  ARGV_OPTS['r'] ? paths.sort!.reverse! : paths.sort!
else
  paths << SPECIFIED_PATH
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
if ARGV_OPTS['l']
  puts "total #{blocks_total}" if paths.size > 1
  paths.each do |path|
    name = if SPECIFIED_PATH.directory?
             path.basename.to_s
           else
             ARGV[0]
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
elsif SPECIFIED_PATH.directory?
  COLUMN_SIZE = 3
  required_row_size = (paths.size.to_f / COLUMN_SIZE).ceil
  containers = Array.new(COLUMN_SIZE) { [] }
  paths.each_with_index do |path, idx|
    name = path.basename.to_s.ljust(name_length_max)
    assigned_idx = idx.div(required_row_size)
    containers[assigned_idx] << name
  end
  containers.shift.zip(*containers) { puts _1.join("\t") }
else
  puts ARGV[0]
end
