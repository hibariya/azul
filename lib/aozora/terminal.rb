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
          person = shelf.persons.find{|p|atoz(p.id.to_i)==args.first}
          person.works.map{|w|"[#{atoz(w.id.to_i)}] #{w.title}"}.join "\n"
        end

        def open(args)
          shelf = Shelf.open
          work = shelf.works.find{|w|atoz(w.id.to_i)==args.first}
          shelf.fetch work
        
        end

        private
        def atoz(num)
          num.to_s(26).scan(/./).map{|c| 'abcdefghijklmnopqrstuvwxyz'.scan(/./)[c.to_i(26)] }.join
        end
      end
    end

    def self.ready
      load CONF_FILE if File.exist? CONF_FILE
      Shelf.open.load
      Readline.vi_editing_mode
      Readline.completion_proc = lambda {|word|
        (Command.methods-methods).
          grep(/\A#{Regexp.quote word}/)
      }
      while buf = Readline.readline('> ', true)
        command, *pipes = buf.split(/\|/).map!{|m|m.strip}
        command, *args = command.split(/\s/).map!{|m|m.strip}
        res = Command.__send__(command, args)
        system("echo \"#{res}\" "+
               (pipes.empty? ? '': '|'+pipes.join('|')))
      end

    end

  end
end
