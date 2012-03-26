require 'cinch'
require 'configru'
require_relative 'memory'

Configru.load do
  just 'config.yml'

  defaults do
    port 6667
    max_bangs 3
  end
end

bot = Cinch::Bot.new do
  configure do |c|
    c.server   = Configru.server
    c.port     = Configru.port
    c.nick     = Configru.nick
    c.channels = Configru.channels

    @max_bangs = Configru.max_bangs
    @ch_user_memory = {}
    @channel_memory = {}
  end

  helpers do
    def regex_replace(target, match, replace, replace_all, nick)
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

      return prefix, answer
    end
  end

  on :channel do |m|
    @channel_memory[m.channel.name] ||= Memory.new(@max_bangs)
    @ch_user_memory[m.channel.name] ||= {}
    @ch_user_memory[m.channel.name][m.user.nick] ||= Memory.new(@max_bangs)

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
        next
      end

      extra_slashes = flags.delete!('/')

      if flags.include?('?')
        snappy_reply = [
          "I don't know. Why don't you ask yourself?",
          "How should I know?",
          "Why would I know that?",
          "Yes. Very yes.",
          "Are you insane?",
          "I don't know. Have you tried asking lazybot??"
        ].sample
        m.reply(snappy_reply, true)
        next
      end

      regex_opts = []
      regex_opts << Regexp::IGNORECASE if flags.delete!('i')
      regex_opts << Regexp::EXTENDED if flags.delete!('x')
      regex_opts << Regexp::MULTILINE if flags.delete!('m')
      replace_all = flags.delete!('g')

      if flags.size != 0 && extra_slashes
        m.reply("Ignoring extra slashes and unrecognized flags: #{flags}", true)
      elsif extra_slashes
        m.reply("Ignoring extra slashes.", true)
      elsif flags.size != 0
        m.reply("Ignoring unrecognized flags: #{flags}", true)
      end

      begin
        match = Regexp.new(match, regex_opts.reduce(:|))
      rescue RegexpError => err
        m.reply(err.message.capitalize, true)
        next
      end

      target = if bangs.length == 0
        @channel_memory[m.channel][0] && @channel_memory[m.channel][0][1]
      else
        @ch_user_memory[m.channel][m.user.nick][-bangs.length]
      end

      if !target
        m.reply("My memory doesn't go back that far!", true)
        next
      end

      nick = if bangs.length > 0
        m.user.nick
      else
        @channel_memory[m.channel][0][0]
      end

      prefix, answer = regex_replace(target, match, replace, replace_all, nick)

      # If s/// doesn't change anything, it will try !s///, !!s///, etc, up
      # to the maximum number of exclamation marks. If the last !!!s/// fails,
      # it will try to use previous lines from global channel memory.
      if bangs.length == 0 && target == answer
        nick = m.user.nick
        1.upto(@max_bangs) do |i|
          target = @ch_user_memory[m.channel][m.user.nick][-i]
          break if target.nil?

          prefix, answer = regex_replace(target, match, replace, replace_all, nick)

          break if answer != target
        end

        # Try global channel memory.

        1.upto(@max_bangs) do |i|
          entry = @channel_memory[m.channel][-i]
          break if entry.nil?
          nick, target = entry

          prefix, answer = regex_replace(target, match, replace, replace_all, nick)

          break if answer != target
        end
      end

      next if target == answer

      # Update the string in @ch_user_memory or @channel_memory.
      target.replace(answer)

      m.reply(prefix + answer)
    elsif m.message =~ /^#{Regexp.escape(m.bot.nick)}[:,]\s*help\s*$/
      m.reply("I perform Perl-style s/// regex replacements in the channel" \
              "using Ruby regex. If you prepend '!', I will only look at" \
              "*your* last line. You can use up to #{@max_bangs} '!'s to" \
              "look that many lines back. Ruby regex docs at" \
              "http://is.gd/rubyregexp", true)
    elsif !m.ctcp? || m.ctcp_command == 'ACTION'
      @ch_user_memory[m.channel][m.user.nick] << m.message
      @channel_memory[m.channel] << [m.user.nick, m.message]
    end
  end
end

bot.start

