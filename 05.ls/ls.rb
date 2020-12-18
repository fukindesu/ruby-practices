#!/usr/bin/env ruby
# frozen_string_literal: true

exit if __FILE__ != $PROGRAM_NAME

require 'optparse'
require 'pathname'
require 'etc'

# コマンドラインオプションの処理
begin
  argv_opts = ARGV.getopts('alr')
rescue OptionParser::ParseError
  puts '[ERROR] 対応できないオプション名が含まれていました'
  exit
end

# 指定パスの処理
case ARGV.size
when 0
  specified_path = Pathname.new(Dir.getwd)
when 1
  if FileTest.exist?(ARGV[0]) || FileTest.symlink?(ARGV[0])
    specified_path = Pathname.new(ARGV[0]).expand_path
  else
    puts "[ERROR] #{ARGV[0]} が見つかりませんでした"
    exit
  end
else
  puts '[ERROR] パスの指定は1つだけでお願いします'
  exit
end

# 適切なFile::Statオブジェクトを返すメソッド
def appropriate_stat(path)
  path.symlink? ? path.lstat : path.stat
end

# 指定パスからPathnameオブジェクトを作成
paths = []
name_length_max = 0
blocks_total = 0
if specified_path.directory?
  Dir.foreach(specified_path) do |file|
    next if !argv_opts['a'] && file.start_with?('.')

    path = Pathname.new(File.join(specified_path, file))
    paths << path
    name_length_max = [name_length_max, path.basename.to_s.length].max
    blocks_total += appropriate_stat(path).blocks
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

# `-l`オプション付きの出力
if argv_opts['l']
  puts "total #{blocks_total}" if paths.size > 1
  paths.each do |path|
    stat = appropriate_stat(path)
    name = if path.symlink?
             "#{path.basename} -> #{path.readlink}"
           else
             path.basename.to_s
           end
    puts [
      ftype_to_chr(stat) + mode_to_rwx_trio(stat),
      stat.nlink.to_s,
      Etc.getpwuid(stat.uid).name,
      Etc.getgrgid(stat.gid).name,
      stat.size.to_s,
      stat.mtime.strftime('%-m %-d %H:%M'),
      name
    ].join(' ')
  end
# `-l`オプション無しの出力
else
  COLUMN_SIZE = 3
  required_row_size = (paths.size.to_f / COLUMN_SIZE).ceil
  containers = Array.new(COLUMN_SIZE) { [] }
  paths.each_with_index do |path, idx|
    name = path.basename.to_s.ljust(name_length_max)
    assigned_idx = idx.div(required_row_size)
    containers[assigned_idx] << name
  end
  containers.shift.zip(*containers) { puts _1.join("\t") }
end