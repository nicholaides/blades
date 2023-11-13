require_relative "blades/version"

require "fileutils"
require "pathname"

module Blades
  def self.sh_to_pipe(*cmd)
    stdout_r, stdout_w = IO.pipe
    system(*cmd, exception: true, out: stdout_w)
    stdout_w.close
    stdout_r
  end

  def self.sh_to_file(*cmd, dst)
    IO.copy_stream sh_to_pipe(*cmd), dst
  end

  def self.find_all = Dir["**/*.tmpl.*"].map { Template.new(_1) }

  class Template
    attr_accessor :src

    def initialize(src)
      @src = Pathname(src)
    end

    def dst = src.sub(/\.tmpl..+$/, "")

    def ext?(str) = dst.extname == str

    def executable? = File.executable?(src)

    def compile_to_dst = Blades.sh_to_file "./#{src}", dst

    def clean
      FileUtils.rm(dst) if File.exist?(dst)
    end

    def dependencies
      File
        .readlines(src)
        .flat_map { _1.split(/\bblades?:dependency\s+/)[1]&.chomp&.split || [] }
        .map { src.parent + _1 }
    end
  end
end
