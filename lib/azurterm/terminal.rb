module Azurterm
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

        def set(args)
          Azurterm::Config.start do
            __send__(args.first, args.last)
          end
          nil
        end

        def reload(args)
          Terminal.prepare
          nil end
        
        def updatedb(args)
          Shelf.open.reload
          nil end

        private
        def atoz(num)
          num.to_s(26).scan(/./).map{|c| 'abcdefghijklmnopqrstuvwxyz'.scan(/./)[c.to_i(26)] }.join
        end
      end
    end

    def self.prepare
      load CONF_FILE if File.exist? CONF_FILE
      Shelf.open.load
      Readline.__send__("#{Azurterm.config.editing_mode}_editing_mode") if Azurterm.config.editing_mode
      Readline.completion_proc = lambda do |word|
        (Command.methods-methods).
          grep(/\A#{Regexp.quote word}/)
      end
    end

    def self.ready
      prepare
      while buf = Readline.readline('> ', true)
        begin
        command, *pipes = buf.split(/\|/).map!{|m|m.strip}
        command, *args = command.split(/\s/).map!{|m|m.strip}
        res = Command.respond_to?(command)? 
          Command.__send__(command, args): "Command #{command} Not Defined."
          system("echo \"#{res}\" "+
                 (pipes.to_s.empty? ? '': '|'+pipes.join('|'))) unless res.to_s.empty?
        rescue Exception => e
          puts "#{e.class} #{e.message}"
        end
      end

    end
  end
end
