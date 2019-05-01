# frozen_string_literal: true

require 'nokogiri'

class ZineFix
  DOCEXT = %w[.htm .html .xhtml .xht .xml].freeze
  ATTRS = %w[href src].freeze
  def downcase_attributes
    Dir.glob(File.join(@zin_dir, '**/**')).each do |file|
      unless File.file?(file) && DOCEXT.include?(File.extname(file))
        yield({ processed: false, file: file }) if block_given?
        next
      end
      processed = false
      doc = Nokogiri::HTML(IO.binread(file))
      ATTRS.each do |attr|
        doc.xpath("//*[@#{attr}]").each do |element|
          val = element.attributes[attr].value
          unless val.match?(%r/^\p{Alnum}+::\/\//)
            processed = true
            element.attributes[attr].value = val.downcase
          end
        end
      end
      IO.binwrite(file, doc.to_s) if processed
      yield({ processed: processed, file: file }) if block_given?
    end
  end
end
