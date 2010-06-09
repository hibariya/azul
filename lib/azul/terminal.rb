module Azul
  class Terminal
    CONF_FILE = File.join(LOCAL_FILES_DIR, 'config')

    class Commands
      class << self
        def search(args)
          args = ['all', args.first] if args.length<2
          mode, word = args
          mode = case mode
                 when 'author' then :person
                 when 'title' then :work
                 else mode.intern
                 end
          Terminal.shelf.search mode=>word.to_s
          persons = Terminal.shelf.persons
          case persons.length
          when 0 then nil
          when 1 then take atoz persons.first.rownum
          else persons.map{|p|"[#{atoz(p.rownum)}] #{p.name}"}.join "\n"
          end
        end

        def take(args)
          return nil if Terminal.shelf.persons.empty?
          Terminal.shelf.persons = [shelf.persons.find{|p|atoz(p.rownum)==args.first}]
          list
        end
       alias :select :take

        def list(args=nil)
          return nil if Terminal.shelf.persons.empty?
          Terminal.shelf.persons.first.works.
            map{|w|"[#{atoz(w.rownum)}] #{w.title}"}.join "\n"
        end
        alias :ls :list

        def open(args)
          work = Terminal.shelf.works.find{|w|atoz(w.rownum)==args.first}
          work ? shelf.fetch(work): nil
        end
        alias :view :open

        def set(args)
          Terminal.config.start do
            __send__(args.first, args.last)
          end
          reload
        end

        def reload(args=nil)
          puts Terminal.config.attributes.inspect
          Terminal.change_editing_mode Terminal.config.editing_mode || 'emacs'
          Terminal.change_color Terminal.config.color || 0
          nil
        end

        def updatedb(args=nil)
          Terminal.shelf.reload
          nil end

        # sub commands {{{
        def person(args=nil); 'usage: search person [person word]' end
        def all(args=nil); 'usage: search all [search word]' end
        def work(args=nil); 'usage: search works [title word]' end
        # }}}

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

      def config_default
        config = Config.new
        config.start do
          base_uri 'http://mirror.aozora.gr.jp/'
          color 34
        end
      end

      def ready
        config, shelf = config_default, Shelf.new
        shelf.config = config
        self.class.__send__(:define_method, :config){ config }
        self.class.__send__(:define_method, :shelf){ shelf }
        load CONF_FILE if File.exist? CONF_FILE
        shelf.load

        change_editing_mode config.editing_mode || 'emacs'
        change_color config.color || 0
        Readline.completion_proc = lambda do |word|
          (Commands.methods-methods).
            grep(/\A#{Regexp.quote word}/)
        end

        puts "[#{APP_NAME} Version #{VERSION}]"
        while buf = Readline.readline("#{APP_NAME}> ", true)
          begin
            cmd, *pipes = buf.to_s.split(/\|/).map!{|m|m.strip}
            cmd, *args = cmd.to_s.split(/\s/).inject([]){|r,c|c.empty?? r: r<<c}
            next if cmd.nil?
            res = Commands.__send__(cmd, args) 
            resfile = File.join(config.cache_dir, '.cache')
            File.open(resfile, 'w'){|f| f.puts res }
            system("cat #{resfile} "+
                   (pipes.to_s.empty?? '': '|'+pipes.join('|'))) unless res.to_s.empty?
          rescue NoMethodError => e
            puts "Command #{cmd} not defined."
          rescue OpenURI::HTTPError => e
            puts "HTTP Error."
          rescue Exception => e
            puts "Command #{cmd} failure."
            puts "raised: #{e.class} #{e.message}"
            puts $@
          end
        end
      end

    end

  end
end
