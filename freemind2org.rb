#!/usr/bin/env ruby
# Sean O'Halpin
# rough hack to convert a freemind .mm file to my flavour of .org

$:.unshift File.dirname(File.expand_path(__FILE__))
require 'rubygems'
require 'rexml/document'
require 'rexml/xpath'
require 'pp'
require 'parse_args'

@head_level = 0
@item_level = 0

def dbg(txt)
  STDERR.puts txt if $FO_DEBUG
end

def lput(level, text, style = :text)
  #STDERR.puts [:lput, level, text, style].inspect
  io = $FO_DEBUG ? STDERR : STDOUT
  filler = ' '
  case style
  when :head
    #indent [0..(level - 1)] = '=' * level
    indent = ('=' * level) + ' '
    @head_level = level
  when :item
#    item_level = level - @head_level
#    item_level = level
    level -= 1
    indent = filler * (((level * 2) - (@head_level * 2) + 2))
    if indent.size < 2
      indent = "   "
    end
    indent[-2] = '-'
  when :text
    level -= 1
    indent = filler * (((level * 2) - (@head_level * 2) + 2))
  end
  #io.print format("%03d ", level)
  io.print indent
  io.puts text
end

# does not handle richcontent nodes yet

def visit(level, node)
  #lput level, "#{node.name}["
  style = :item
  #style = :text
  att_style = node.attributes['style'] || node.attributes['STYLE']
  if att_style.to_s !~ /^\s*$/
    case att_style
    when 'bubble'
      style = :head
    when 'fork'
      style = :item
    else
      STDERR.puts "Unknown style '#{att_style}' for element #{node}"
     end
  end
  if node.attributes['TEXT'].to_s !~ /^\s*$/
    lput level, node.attributes['TEXT'], style
  end
  if node.text.to_s !~ /^\s*$/
    lput level, node.text, style
  end
  if node.elements.size > 0
    node.elements.each do |child|
      level += 1
      visit(level, child)
      level -= 1
    end
  end
  #lput level, "]"
end

#pp doc[0].elements[1].elements[1]

# get the XML data as a string

def scriptname
  File.basename($0)
end

def arg_error(txt)
#  raise ArgumentError, txt, caller[-2]
  puts "#{scriptname} - error: #{txt}"
  exit 1
end

def main(argv)
  args, opts = parse_args(argv, %w[d])
  $FO_DEBUG = opts[:d]
  filename = args.shift
  #p filename
  if filename == '-'
    xml_data = $stdin.read
  else
    arg_error "Missing filename" if !filename
    arg_error "No such file" if !File.exist?(filename)
    xml_data = File.read(filename)
  end
  # extract event information
  doc = REXML::Document.new(xml_data)

  # skip root node

  visit(1, REXML::XPath.first( doc, "//node" ))
end

main ARGV

=begin

to do:
- sort out formatting of items
  - maybe have them flush left (I use that a lot) rather than indented below headings?
=end
