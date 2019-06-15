# frozen_string_literal: true

require 'pathname'

Dir.glob(File.join(__dir__, 'zinefix/*.rb')) { |file| require_relative file }

class ZineFix
  attr_reader :zin_dir, :all_files

  def initialize(zin_dir)
    unless File.directory?(zin_dir)
      raise "Pod ścieżką #{params[:dirname]}"\
            'nie znajduje się folder'
    end

    @zin_dir = Pathname.new(zin_dir).cleanpath.to_s
    refresh_zinedir
  end

  def refresh_zinedir
    @all_files = Dir.glob(File.join(@zin_dir, '**/**')).map(&:b)
  end
end


