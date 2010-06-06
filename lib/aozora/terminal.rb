module Aozora
  class Terminal
    class Command
      class << self
        def search(args)
          args = ['all', args.first] if args.length<2
          mode, word = args
          shelf = Shelf.open
          shelf.search mode.intern=>word
          shelf.persons.map{|p|"[#{atoz(p.id.to_i)}] #{p.name}"}.join "\n"
        end

        def take(args)
          shelf = Shelf.open

        end

        private
        def atoz(num)
          num.to_s(26).scan(/./).map{|c| 'abcdefghijklmnopqrstuvwxyz'.scan(/./)[c.to_i(26)] }.join
        end
      end
    end

    def self.ready
      Shelf.open
      Readline.vi_editing_mode
      Readline.completion_proc = lambda {|word|
        (Command.methods-methods).
          grep(/\A#{Regexp.quote word}/)
      }
      while buf = Readline.readline('> ', true)
        command, *pipes = buf.split(/\|/).map!{|m|m.strip}
        command, *args = command.split(/\s/).map!{|m|m.strip}
        res = Command.__send__(command, args.flatten)
        system("echo \"#{res}\" "+
               (pipes.empty? ? '': '|'+pipes.join('|')))
      end

    end

  end
end
