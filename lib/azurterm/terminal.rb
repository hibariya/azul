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
          reload
        end

        def reload(args)
          Terminal.change_editing_mode Azurterm.config.editing_mode || 'emacs'
          Terminal.change_color Azurterm.config.color || 0
          nil
        end
        
        def updatedb(args)
          Shelf.open.reload
          nil end

        private
        def atoz(num)
          num.to_s(26).scan(/./).map{|c| 'abcdefghijklmnopqrstuvwxyz'.scan(/./)[c.to_i(26)] }.join
        end
      end
    end

    class << self
      def change_color(c)
        print "\e[0m\e[#{c}m"
      end

      def change_editing_mode(e)
        Readline.__send__("#{e}_editing_mode")
      end

      def ready
        load CONF_FILE if File.exist? CONF_FILE
        Shelf.open.load
        change_editing_mode Azurterm.config.editing_mode || 'emacs'
        change_color Azurterm.config.color || 0
        Readline.completion_proc = lambda do |word|
          (Command.methods-methods).
            grep(/\A#{Regexp.quote word}/)
        end
        puts "[#{APP_NAME} Version #{VERSION}]"

        while buf = Readline.readline("#{APP_NAME}> ", true)
          begin
            command, *pipes = buf.to_s.split(/\|/).map!{|m|m.strip}
            command, *args = command.to_s.split(/\s/).map!{|m|m.strip}
            next if command.nil?
            res = Command.respond_to?(command)? 
              Command.__send__(command, args): "Command #{command} Not Defined."
              system("echo \"#{res}\" "+
                     (pipes.to_s.empty? ? '': '|'+pipes.join('|'))) unless res.to_s.empty?
          rescue Exception => e
            puts "Command #{command} Failure."
            puts "#{e.class} #{e.message}"
            puts $@
          end
        end
      end
    end

  end
end
