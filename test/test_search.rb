require 'rubygems'
require 'faker'
require '../search'
require '../searcher'

searcher = Searcher.new

what_to_respond_to = "right affects including schemas"

responses = searcher.look_for_response_to(what_to_respond_to, {1 => 5})

puts responses.join("\n")

