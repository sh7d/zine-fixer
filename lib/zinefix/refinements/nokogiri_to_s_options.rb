# frozen_string_literal: true

require 'nokogiri'

module NokogiriToSOptions
  refine Nokogiri::XML::Node do
    def to_s(options = {})
      document.xml? ? to_xml(options) : to_html(options)
    end
  end
end
