# frozen_string_literal: true

require 'nokogiri'
require 'rchardet'
require_relative 'refinements/nokogiri_to_s_options'
class ZineFix
  using NokogiriToSOptions

  DOCEXT = %w[.htm .html .xhtml .xht .xml].freeze
  ATTRS = %w[href src].freeze
  SKIP_REGEXPS = [%r{^\p{Alnum}+::\/\/}, /^javascript\:/].freeze
  def downcase_attributes
    @all_files.each do |file|
      next unless File.file?(file)

      unless DOCEXT.include?(File.extname(file))
        yield({ processed: false, file: file }) if block_given?
        next
      end
      processed = false
      file_content = IO.binread(file)
      begin
        file_content = file_content.force_encoding(
          (CharDet.detect(file_content)['encoding'] || Encoding::BINARY)
        )
      rescue
        binding.pry
      end
      doc = Nokogiri::HTML(file_content)
      ATTRS.each do |attr|
        doc.xpath("//*[@#{attr}]").each do |element|
          val = element.attributes[attr].value
          next if SKIP_REGEXPS.any? { |r| r.match?(val) }

          element.attributes[attr].value = val.downcase.tr(
            '\\', '/'
          ).encode((doc.encoding))
        end
      end
      doc = doc.to_s.force_encoding(Encoding::BINARY)
      processed = true if doc != file_content
      IO.binwrite(file, doc) if processed
      yield({ processed: processed, file: file }) if block_given?
    end
  end
end
