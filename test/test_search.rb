require 'rubygems'
require 'faker'
require '../search'
require '../searcher'

searcher = Searcher.new

# what_to_respond_to = "A Constitutional scholar, you are not"
what_to_respond_to = "translate case manager for me"

responses = searcher.look_for_response_to(what_to_respond_to, {5 => 2, 2 => 5, 1 => 4})

# responses.collect{ |rs| rs.join(", ")}.join("\n\n")

puts responses.collect{ |rs| rs.join(", ")}.join("\n\n")

