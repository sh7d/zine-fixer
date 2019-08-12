# frozen_string_literal: true

require 'pathname'
require 'set'

class ZineFix
  TEXTFILESEXT = %w[.htm .html .xhtml .xht .xml .js .css].freeze
  def downcase_files_strings
    delete_zin_prefix = ->(dir) { dir.delete_prefix(@zin_dir + '/') }
    files_relative = @all_files.reverse.select(&File.method(:file?))
                               .map(&delete_zin_prefix)
    @all_files.reverse_each do |file|
      unless File.file?(file) && DOCEXT.include?(File.extname(file))
        yield({ processed: false, file: file }) if block_given?
        next
      end
      fp = Pathname.new(file.delete_prefix(@zin_dir + '/'))
      fp = fp.ascend.to_a.map(&:to_s).select do |s|
        File.directory?(File.join(@zin_dir, s))
      end
      strings = Set.new
      fp.each do |f|
        f_prefix = File.join(@zin_dir, f)
        curr_str = Dir.glob(File.join(f_prefix, '**/**')).to_a
                      .reverse.reject(&File.method(:directory?))
                      .map(&delete_zin_prefix).map do |ff|
                        ff.delete_prefix(f + '/')
                      end.reject(&:empty?)
        strings.merge(curr_str)
      end
      strings.merge(files_relative)
      file_str = IO.binread(file)
      file_str_r = case_insensitive_downcase(file_str, strings)
      processed = false
      unless file_str == file_str_r
        IO.binwrite(file, file_str_r)
        processed = true
      end
      yield({ processed: processed, file: file }) if block_given?
    end
  end

  private

  def case_insensitive_downcase(fstr, array_of_str)
    array_of_str.each do |str|
      str = str.b
      pstr = str.split('/').map do |str|
        Regexp.escape(str).gsub(/(\\ )+/, '(?:\\ +|(%20)+)')
      end.join('(/+|\\\\+)')
      rgx = Regexp.new(
        pstr, Regexp::IGNORECASE
      )
      fstr = fstr.gsub(rgx, str.downcase)
    end
    fstr.freeze
  end
end
