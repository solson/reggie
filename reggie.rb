require 'cinch'

bot = Cinch::Bot.new do
  configure do |c|
    c.server   = "irc.tenthbit.net"
    c.nick     = "reggie"
    c.channels = ["#programming", "#offtopic", "#bots"]
    
    @max_bangs = 3
    @ch_user_memory = {}
    @channel_memory = {}
  end
  
  on :channel do |m|
    @channel_memory[m.channel.name] ||= []
    @ch_user_memory[m.channel.name] ||= {}
    @ch_user_memory[m.channel.name][m.user.nick] ||= []
      
    if m.message =~ %r"^(!*)s/((?:[^\\/]|\\.)*)/((?:[^\\/]|\\.)*)/(?:(\S*))?"
      bangs   = $1
      match   = $2
      replace = $3
      flags   = $4
      
      # This replaces \/ with / in the replacement part (that is, s//<here>/),
      # because / needs to be escaped by users
      replace.gsub!(/(?<!\\)((?:\\\\)*)\\\//, '\1/')
      
      if bangs.length > @max_bangs
        m.reply("I only support up to #{@max_bangs} !'s.", true)
        m.reply('in bed') if rand(100) == 42
        next
      end
      
      regex_opts = []
      regex_opts << Regexp::IGNORECASE if flags.delete!('i')
      regex_opts << Regexp::EXTENDED if flags.delete!('x')
      regex_opts << Regexp::MULTILINE if flags.delete!('m')
      replace_all = flags.delete!('g')
      
      m.reply("Ignoring unrecognized flags: #{flags}", true) if flags.size != 0
      
      begin
        match = Regexp.new(match, regex_opts.reduce(:|))
      rescue RegexpError => err
        m.reply("RegexpError: #{err.message}", true)
        next
      end

      target = if bangs.length == 0
        @channel_memory[m.channel][1]
      else
        @ch_user_memory[m.channel][m.user.nick][-bangs.length]
      end
      
      if target == nil
        m.reply("My memory doesn't go back that far!", true)
        m.reply('in bed') if rand(100) == 42
        next
      end

      nick = if bangs.length > 0
        m.user.nick
      else
        @channel_memory[m.channel][0]
      end

      if target =~ /^\x01ACTION (.*)\x01$/
        prefix = "* #{nick} "
        target = $1
      else
        prefix = "<#{nick}> "
      end

      answer = if replace_all
        target.gsub(match, replace)
      else
        target.sub(match, replace)
      end

      # If s/// doesn't change anything, it will try !s///, !!s///, etc, up
      # to the maximum number of exclamation marks.
      if bangs.length == 0 && target == answer
        nick = m.user.nick
        1.upto(@max_bangs) do |i|
          target = @ch_user_memory[m.channel][m.user.nick][-i]

          if target =~ /^\x01ACTION (.*)\x01$/
            prefix = "* #{nick} "
            target = $1
          else
            prefix = "<#{nick}> "
          end

          answer = if replace_all
            target.gsub(match, replace)
          else
            target.sub(match, replace)
          end

          break if answer != target
        end
      end
      
      next if target == answer

      m.reply(prefix + answer)
    elsif m.message =~ /^#{Regexp.escape(m.bot.nick)}[:,]\s*help\s*$/
      m.reply("I perform Perl-style s/// regex replacements in the channel. If you prepend '!', I will only look at *your* last line. You can use up to #{@max_bangs} '!'s to look that many lines back. Ruby regex docs at http://is.gd/rubyregex", true)
    elsif !m.ctcp? || m.ctcp_command == 'ACTION'
      @ch_user_memory[m.channel][m.user.nick] << m.message
      @ch_user_memory[m.channel][m.user.nick].unshift if @ch_user_memory[m.channel][m.user.nick].length > @max_bangs
      @channel_memory[m.channel] = [m.user.nick, m.message]
    end
  end
end      

bot.start

