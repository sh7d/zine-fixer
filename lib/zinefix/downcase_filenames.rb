# frozen_string_literal: true

require 'fileutils'
require 'pathname'

class ZineFix
  def downcase_filenames
    @all_files.reverse_each do |file|
      dfile = Pathname.new(file)
      dfile = File.join(dfile.parent.to_s, dfile.basename.to_s.downcase)
      if file != dfile
        FileUtils.mv(file, dfile)
        yield({ processed: true, file: file }) if block_given?
      elsif block_given?
        yield({ processed: false, file: file })
      end
    end
    refresh_zinedir
    true
  end
end
