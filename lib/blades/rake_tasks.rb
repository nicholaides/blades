require "rake/tasklib"
require "rake/clean"

require_relative "../blades"
CLEAN.include "coverage"

module Blades
  class RakeTasks < Rake::TaskLib
    def initialize(
      namespace_name: :blades,
      before: proc {},
      after: proc {},
      after_all: proc {}
    )
      super()

      task namespace_name => "#{namespace_name}:build"

      namespace namespace_name do
        templates = Blades.find_all

        task build: templates.map(&:dst) do
          after_all.call(@generated_templates) if @generated_templates&.any?
        end

        templates.each do |template|
          file template.dst => [template.src, *template.dependencies] do
            if template.executable?
              before.call template
              template.compile_to_dst
              after.call template
              (@generated_templates ||= []) << template
            else
              warn "Skip compiling #{template.dst} because #{template.src} is not executable"
            end
          end
        end

        CLEAN.include(*templates.map(&:dst))
        task :clean do
          templates.each(&:clean)
        end
      end
    end
  end
end
