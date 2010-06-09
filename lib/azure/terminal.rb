module Azure
  class Terminal

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
          Terminal.shelf.search mode=>word
          persons = Terminal.shelf.persons
          case persons.length
          when 0 then nil
          when 1 then take atoz persons.first.rownum
          else persons.map{|p|"[#{atoz(p.rownum)}] #{p.name}"}.join "\n"
          end
        end

        def take(args)
          Terminal.shelf.persons = [shelf.persons.find{|p|atoz(p.rownum)==args.first}]
          list
        end
       alias :select :take

        def list(args=nil)
          Terminal.shelf.persons.first.works.
            map{|w|"[#{atoz(w.rownum)}] #{w.title}"}.join "\n"
        end
        alias :ls :list

        def open(args)
          work = Terminal.shelf.works.find{|w|atoz(w.rownum)==args.first}
          shelf.fetch work
        end
        alias :view :open

        def set(args)
          Terminal.config.start do
            __send__(args.first, args.last)
          end
          reload
        end

        def reload(args=nil)
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
          base_uri 'http://www.aozora.gr.jp/'
          database_path 'index_pages/list_person_all.zip'
          person_path 'cards/%s/'
          card_file 'card%s.html'
          database_expire 86400
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
            res = Commands.respond_to?(cmd)? 
              Commands.__send__(cmd, args): "Command #{cmd} not defined."
            resf = File.join(CACHE_DIR, '.cache')
            File.open(resf, 'w'){|f| f.puts res }
            system("cat #{resf} "+
                   (pipes.to_s.empty?? '': '|'+pipes.join('|'))) unless res.to_s.empty?
          rescue Exception => e
            puts "Command #{cmd} failure."
            puts "#{e.class} #{e.message}"
            puts $@
          end
        end
      end

    end

  end
end
