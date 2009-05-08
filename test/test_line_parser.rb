require 'rubygems'
require 'hpricot'
require 'net/http'
require 'yaml'

require '../parsers/line_parser.rb'
require '../parsers/content_extractor.rb'

article_url = "http://www.mcsweeneys.net/2009/5/7wood.html"
# article_url = "http://www.mcsweeneys.net/1998/11/23concise.html"

contents = Net::HTTP.get(URI.parse(article_url))

extractor = ContentExtractor.new(contents)

p_texts = extractor.p_texts

# puts "Story contents:\n" + p_texts.join("\n")

line_parser = LineParser.new(p_texts)

puts line_parser.lines.join("\n")