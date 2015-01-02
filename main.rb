require 'bundler/setup'
require 'daybreak'
require 'cinch'

begin
  db = Daybreak::DB.new "./funbot.db"

  Cinch::Bot.new do
    configure do |c|
      c.server   = "irc.freenode.net"
      c.channels = ["##the_basement"]
      c.nick     = "warden`"
    end
    
    on :message, /^\..*/ do |m|
      @m = m

      def reply(str)
        @m.reply str
      end

      x      = m.message.split(/\s+/)
      cmd    = x[0][1..-1]
      args   = x[1..-1]
      chan   = m.channel
      sender = m.user
      adminp =  sender.host == 'botters/entel'    

      #    eval open(File.join(File.dirname(__FILE__), "sandbox.rb")).read

      unless chan.nil? 
        if adminp
          if cmd == '?'
            reply 'you are my master ^^;'
          elsif cmd == 'kill'
            bot.quit
          elsif cmd == 'db'
            reply db.inspect
          elsif cmd == 'points' && /^\-?\d+(\.\d+)?$/ === args[1] && args.size == 2
            nick = args[0]
            new_points = args[1].to_f

            if db['points'].nil?
              db['points'] = {nick => new_points}
            elsif not db['points'].has_key? nick
              db['points'][nick] = new_points
            else
              db['points'][nick] += new_points
            end

            db.flush

            reply "#{nick} has been awarded #{new_points} fun points for a total of #{db['points'][nick]}!!"
          elsif cmd == 'achievement' && args.size > 1
            nick        = args[0]
            achievement = args[1..-1].join(" ")

            if db['achievements'].nil?
              db['achievements'] = {}
            end
            if db['achievements'][nick].nil?
              db['achievements'][nick] = []
            end

            db['achievements'][nick] << achievement
            db.flush

            reply "#{nick} has earned the achievement '#{achievement}'"
          end
        end

        if cmd == 'balance'
          points = db['points'][m.user.nick]
          if points.nil?; points = 0; end
          reply "HOLY SHIT you have #{points} fucking fun points dude!!!"
        elsif cmd == 'give' && args.size == 2
          points = args[1].to_f
          if points > 0 && points <= db['points'][sender.nick] && !db['points'][args[0]].nil?
            db['points'][sender.nick] -= points
            db['points'][args[0]] += points
            db.flush

            reply "holy shit this nigga generous! #{sender.nick} gave that bastard #{args[0]} #{points} fun points!"
          end
        elsif cmd == 'achievements'
          if db['achievements'].nil? || !db['achievements'].has_key?(sender.nick)
            reply "you dont have any fucking achievements dude"
          elsif db['achievements'].has_key? m.user.nick
            reply db['achievements'][m.user.nick].join(", ")
          end
        end
      end
    end
  end.start
ensure
  db.close
end
