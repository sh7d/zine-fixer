# frozen_string_literal: true
class ZineFix
  module FileExt
    JS = ['.js', '.html', '.htm'].freeze
  end
  def js_top
    @all_files.each do |file|
      unless File.file?(file) && FileExt::JS.include?(File.extname(file))
        yield({ processed: false, file: file }) if block_given?
        next
      end
      processed = false
      file_content = IO.binread(file)
      file_content = file_content.force_encoding(Encoding::BINARY)
      used_regex = case File.extname(file)
                   when '.js'
                     /((\s+)|(\;\s*))(top\()/i
                   when /\.htm(?:l|)$/
                     /((^|\s+)|(\;\s*)|\"|\')(top\()/i
                   end
      subtop = '\1le_top('.dup.force_encoding(file_content.encoding)
      file_content_post = file_content.gsub(
        used_regex,
        subtop
      )
      if file_content != file_content_post
        IO.binwrite(file, file_content_post.force_encoding(Encoding::BINARY))
        processed = true
      end
      yield({ processed: processed, file: file }) if block_given?
    end
  end
end
