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

  module Rel
    module_function

    def __caller_path__
      Pathname.new(caller_locations.drop_while { _1.path == __FILE__ }.first.path)
    end

    def relative_file(path) = __caller_path__.parent + path

    def related_file(ext) = related_file_to(__caller_path__, ext)

    def related_file_to(base, ext)
      possible_names = descend_exts(append_ext(base, ".X")).map { _1.sub_ext(ext) }

      possible_names.detect { File.exist?(_1) } || raise(
        "Couldn't find related #{ext.inspect} file to #{base.inspect}. Tried: #{possible_names.map { "- #{_1}" }}"
      )
    end

    def append_ext(path, ext) = Pathname.new("#{path}#{ext}")

    # e.g.: descend_exts("foo/bar.a.b.c").to_a => ["foo/bar.a.b.c", "foo/bar.a.b", "foo/bar.a", "foo/bar"]
    def descend_exts(path)
      return to_enum(:descend_exts, path) unless block_given?

      current_path = path

      loop do
        yield current_path

        break if current_path.extname == ""

        current_path = current_path.sub_ext("")
      end
    end
  end

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
