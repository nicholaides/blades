require_relative "blades/version"

require "fileutils"

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

  Template = Struct.new(:src) do
    def dst = src.sub(/\.tmpl..+$/, "")

    def ext?(str) = dst.end_with?(str)

    def executable? = File.executable?(src)

    def compile_to_dst = Blades.sh_to_file "./#{src}", dst

    def clean
      FileUtils.rm(dst) if File.exist?(dst)
    end
  end
end
