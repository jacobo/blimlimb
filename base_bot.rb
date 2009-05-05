require 'irc'
require 'rubygems'
require 'faker'
require 'searcher'

# HOST = 'irc.freenode.net'
# CHAN = '#stagewtf'
# HOST = 'irc.mmm.com'
# CHAN = '#chat'

class BaseBot
  def initialize(nick, host, chan)
    @@already_said ||= []
    @searcher = Searcher.new
    @socket = IRC.new(host, 6667, nick, chan) do |who_said, said_what|
      firstpart, message = said_what.split(":")
      responses = @searcher.look_for_response_to(said_what) - @@already_said
      said_what_reduced = said_what.downcase.gsub(/[^a-z]/,"").split(" ")
      if responses.size > 0
        responses.sort! do |re1, re2|
          r1 = re1[0]
          r2 = re2[0]
          (r2.gsub(/[^a-z]/,"").split(" ") & said_what_reduced).size <=> (r1.gsub(/[^a-z]/,"").split(" ") & said_what_reduced).size
        end
        @@already_said << responses.first[0]
        
        puts "in response to: " + said_what
        puts "I would say: " + responses.first[0]
        # puts "full context: " + responses.first[1]
        puts "--or maybe--"
        puts "I would say: " + responses.last[0]
        puts "----"
        # puts to_say
        
        # msg("PRIVMSG", "observer", to_say)
        # say "#{who_said}: " + responses.first
        # sleep(1+ rand(8))
      end
      # puts "running callback in #{self.inspect} --- #{callback}"
    end
    @nick = nick
  end
  def connect
    puts "Connecting..."
    @socket.connect()
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

RandQuoteBot.new("observer").connect
while(true)
  Thread.pass
end

