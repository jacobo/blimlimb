# require 'rubygems'
# require 'rbot/rfc2812'
# require 'rbot/ircsocket'
# require 'rbot/config'
# require 'rbot/timer'
# require 'rbot/message'
# require 'rbot/irc'
# require 'uri'
require 'irc'

# HOST = 'irc.freenode.net'
# CHAN = '#stagewtf'
HOST = 'irc.mmm.com'
CHAN = '#test_stage_stage'
FROM = 'blim.limb'

def debug(message=nil)
  print "=========DEBUG: #{message}\n" if message
end

class BotPlayer
  attr_reader :nick, :socket, :client, :people_to_thank, :people_to_talk_to
  def initialize(nick, troupe)
    @people_to_thank = []
    @people_to_talk_to = []
    # @socket = Irc::Socket.new([HOST], nil)
    # @client = Irc::Client.new
    @socket = IRC.new(HOST, 6667, nick, CHAN) do |who_said, said_what|
      firstpart, message = said_what.split(":")
      if firstpart == nick
        #handle a message to me
        unless troupe.my_names.include?(nick)
          @people_to_talk_to << [who_said, message]
        end
      elsif said_what[nick]
        unless troupe.my_names.include?(nick)
          @people_to_thank << who_said
        end
        #handle a message that mentions me
      end
      # puts "running callback in #{self.inspect} --- #{callback}"
    end
    @nick = nick
    # @client[:welcome] = proc do |data|
      # @socket.queue "JOIN #{CHAN}"
    # end
  end
  def connect
    # irc = IRC.new('irc.mmm.com', 6667, 'Alt-255', '#stage')
    @socket.connect()
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
    # @socket.connect
    # @client.connect
    # @socket.send :puts, "NICK #{@nick}\nUSER #{@nick} 4 #{FROM} :blimLimb, of #camping"
    # @socket.send :puts, "JOIN #{CHAN}"
    # while true
    #   Thread.pass
    # end
    # Thread.start(self) do |bot|
    #   while true
    #     while bot.socket.connected?
    #       if bot.socket.select
    #         break unless reply = bot.socket.gets
    #         bot.client.process reply
    #       end
    #     end
    #   end
    # end
  end
  def msg(type, where, message)
    # debug("#{type} #{where} :#{message}")
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

class BotTroupe
  attr_accessor :actors, :my_names
  def initialize(script)
    @script = script
    @actors = {}
    @my_names = []
  end
  def parse line
      case line.strip
      #[t] teslyANDERSowens
      #kid = t
      #actor = teslyANDERSowens
      #assigns t to 'teslyANDERSowens'
      when /^\[(\w+)\]\s+(.+?)$/
        kid, actor = $1, $2
        @actors[kid] = BotPlayer.new(actor, self)
        @actors[kid].connect
        puts "Join #{actor}"
      #b= prin
      #kid = b
      #nick = prin
      #renames b to 'prin'
      when /^(\w+)=\s*(.+?)$/
        kid, nick = $1, $2
        puts "#{@actors[kid].nick} is now named #{nick}"
        @actors[kid].renick(nick)
      #t: hehe
      #kid = t
      #msg = hehe
      #sends a message as 't'
      when /^(\w+):\s?(.+?)$/
        kid, msg = $1, $2
        @actors[kid].say(msg)
        puts "<#{@actors[kid].nick}> #{msg}"
      #(t) picks up hanky
      #kid = t
      #msg = picks up hanky
      #emotes message as 't'
      when /^\((\w+)\)\s+(.+?)$/
        kid, msg = $1, $2
        @actors[kid].action(msg)
        puts "** #{@actors[kid].nick} #{msg}"
      #+10
      #waits 10 seconds
      when /^\+\s*(\d+)/
        puts "Wait #{$1} secs"
        sleep $1.to_i
      #* pick a volunteer
      #parse standard in for stuff
      #end it with a *
      when /^\*\s+(.+?)$/
        puts "--- okay, _why: your console - #$1 ---"
        while true
          puppet = $stdin.gets.strip
          if puppet =~ /^\*/
            #enter a * to go back to the script
            break
          end          
          parse puppet
        end 
      when /^\?/
        @actors.each do |a_name, bot|
          puts "[#{a_name}] " + bot.nick
          puts "people_to_thank: " + bot.people_to_thank.inspect
          puts "people_to_talk_to: " + bot.people_to_talk_to.inspect
        end
      #-s away!!
      #bot 's' exits (can't get the exit message to actually work)
      when /^\-(\w+)\s+(.+?)$/
        kid, msg = $1, $2
        @actors[kid].quit(msg)
        puts "Exit #{@actors[kid].nick}"
      end
  rescue => e
      p e.message
      puts e.backtrace.join("\n")
  end
  def act!
    IO.foreach(@script) do |line|
      parse line
      sleep(1+ rand(8))
    end
  end
end

if __FILE__ == $0
  troupe = BotTroupe.new ARGV[0]
  troupe.act!
end
