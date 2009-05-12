require 'irc'
require 'rubygems'
require 'faker'
require 'search'
require 'searcher'

# HOST = 'irc.freenode.net'
# CHAN = '#stagewtf'
HOST = 'irc.mmm.com'
CHAN = '#chat'
# CHAN = '#fight_test'

class RandQuoteBot
  def self.search_patterns
    # combiner.call(5, 2)
    # combiner.call(4, 2)
    # combiner.call(3, 2)
    # combiner.call(2, 5)
    # combiner.call(1, 8)
    [{5 => 2, 2 => 5, 1 => 7},
      {4 => 2, 2 => 4, 1 => 6},
      {3 => 2, 2 => 5},
      {2 => 2, 1 => 5},
      {1 => 4},
      {1 => 3},
      {1 => 2}]
  end
  def initialize(nick)
    @@already_said ||= []
    @@recent_lines = [nil, nil, nil, nil, nil]
    @searcher = Searcher.new
    @socket = IRC.new(HOST, 6667, nick, CHAN) do |who_said, said_what|
      firstpart, message = said_what.split(":")
      what_to_respond_to = message.to_s
      if firstpart == nick
        responded_yet = false
        RandQuoteBot.search_patterns.each do |search_pattern|
          unless responded_yet
            responses = @searcher.look_for_response_to(what_to_respond_to, search_pattern) - @@already_said
            # said_what_reduced = said_what.downcase.gsub(/[^a-z]/,"").split(" ")
            if responses.size > 0
              response_to_say = responses[0,5].rand #select randomly from the top 5 responses
              doc_and_lines, score, to_say = response_to_say
              @@already_said << response_to_say

              @@recent_lines.shift
              @@recent_lines.push({:said => response_to_say, :others_possible => responses[0,5]})
              
              say "#{who_said}: " + to_say
              responded_yet = true
              # sleep(1+ rand(8))
            end
          end
        end
      elsif said_what.index(nick)
        action("will only respond if directly addressed")
      end
      # puts "running callback in #{self.inspect} --- #{callback}"
    end
    @nick = nick
  end
  def connect
    puts "Connecting..."
    @socket.connect()
    action("is hopefully a little less verbose")
    # @socket.send "JOIN observer"
    Thread.new do
      begin
          @socket.main_loop()
      rescue Interrupt
      rescue Exception => detail
          puts detail.message()
          print detail.backtrace.join("\n")
          # retry
      end
    end    
  end
  def msg(type, where, message)
    @socket.send("#{type} #{where} :#{message}")
  end
  def say(message)
    msg("PRIVMSG", CHAN, message)
  end
  def action(message)
    msg("PRIVMSG", CHAN, "\001ACTION #{message}\001")
  end
  def renick(name)
    debug("renick #{name}")
    @nick = name
    @socket.send("NICK #{@nick}")
  end
  def quit(message)
    # debug("quit #{message}")
    action(message)
    @socket.send "QUIT"
    # @socket.send "QUIT :#{message}"
    # @socket.send "PART #{CHAN} :#{message}"
    # @socket.shutdown
  end
end

RandQuoteBot.new("antibot_rc6").connect

Thread.stop

