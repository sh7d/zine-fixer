# frozen_string_literal: true
require 'rkelly'
require 'nokogiri'
require 'pry-byebug'
class ZineFix
  module FileExt
    JS = ['.js'].freeze
  end
  def js_fix_flash
    @all_files.each do |file|
      unless File.file?(file) && FileExt::JS.include?(File.extname(file))
        yield({ processed: false, file: file }) if block_given?
        next
      end
      processed = false
      file_content = IO.binread(file)
      ast = RKelly::Parser.new.parse(file_content)
      if ast.nil?
        yield({ processed: false, file: file }) if block_given?
        next
      end
      #next unless file.end_with?("menu.js")
      ast.each do |node|
        swfnode = false
        next unless node.instance_of?(RKelly::Nodes::FunctionCallNode)

        curr_func = node.value.to_a.last(2).map do |elem|
          elem.respond_to?(:accessor) ? elem.accessor.to_s : elem.value.to_s
        end
        curr_func = curr_func&.reverse&.join('.')
        curr_func.match?(/^document.write(ln|)$/) &&
          swfnode = node.arguments.value[0]

        if swfnode && finger_swf(swfnode.value.to_s)
          fix = fix_swf_node(swfnode.value.to_s)
          swfnode.value = "'" + fix + "'"
        end
      end
      if ast.to_ecma != file_content
        IO.binwrite(file, ast.to_ecma.force_encoding(Encoding::BINARY))
        processed = true
      end
      yield({ processed: processed, file: file }) if block_given?
    end
  end

  private

  def finger_swf(write_str)
    true if write_str.match?(/^.+\.swf/)
  end

  def fix_swf_node(node_string)
    htmlnode = Nokogiri::HTML.fragment(node_string)
    swfobj = htmlnode.children.find { |nd| nd.name == 'object' }
    return false unless swfobj[:classid]

    embed_hash = {
      id: swfobj[:id],
      width: swfobj[:width],
      height: swfobj[:height],
      type: 'application/x-shockwave-flash'
    }
    params = swfobj.children.select { |nd| nd.name == 'param' }
    embed_hash[:data] = params.find { |nd| nd['name'] == 'movie' }['value']
    embed_hash[:bgcolor] = params.find { |nd| nd['name'] == 'bgcolor' }['value']
    embed_hash.delete_if { |_, v| v.nil? || v&.empty? }

    embed = Nokogiri::HTML::Builder.new do |doc|
      doc.object(embed_hash)
    end
    embed.to_html.split("\n")[1..-1].join
  end
end
