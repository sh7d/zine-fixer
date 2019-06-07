# frozen_string_literal: true

require 'nokogiri'
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
      doc = Nokogiri::HTML(file_content, nil, Encoding::BINARY.to_s)
      ATTRS.each do |attr|
        doc.xpath("//*[@#{attr}]").each do |element|
          val = element.attributes[attr].value
          next if SKIP_REGEXPS.any? { |r| r.match?(val) }

          element.attributes[attr].value = val.downcase.tr(
            '\\', '/'
          ).force_encoding((doc.encoding || Encoding::BINARY.to_s))
        end
      end
      doc = doc.to_s.force_encoding(Encoding::BINARY)
      processed = true if doc != file_content
      IO.binwrite(file, doc) if processed
      yield({ processed: processed, file: file }) if block_given?
    end
  end
end
