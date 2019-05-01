# frozen_string_literal: true

require 'pathname'

class ZineFix
  attr_reader :zin_dir

  def initialize(zin_dir)
    unless File.directory?(zin_dir)
      raise "Pod ścieżką #{params[:dirname]}"\
            'nie znajduje się folder'
    end

    @zin_dir = Pathname.new(zin_dir).cleanpath.to_s
  end
end

Dir.glob(File.join(__dir__, 'zinefix/*.rb')) { |file| require_relative file }
