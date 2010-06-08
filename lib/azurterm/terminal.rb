module Azurterm
  class Terminal

    class Commands
      class << self
        def search(args)
          args = ['all', args.first] if args.length<2
          mode, word = args
          Terminal.shelf.search mode.intern=>word
          Terminal.shelf.persons.map{|p|"[#{atoz(p.id.to_i)}] #{p.name}"}.join "\n"
        end

        def take(args)
          Terminal.shelf.persons = [shelf.persons.find{|p|atoz(p.id.to_i)==args.first}]
          list
        end

        def list(args=nil)
          Terminal.shelf.persons.first.works.
            map{|w|"[#{atoz(w.id.to_i)}] #{w.title}"}.join "\n"
        end

        def open(args)
          work = Terminal.shelf.works.find{|w|atoz(w.id.to_i)==args.first}
          shelf.fetch work
        end

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
        config, shelf = config_default, Shelf.new.load
        load CONF_FILE if File.exist? CONF_FILE
        shelf.config = config
        self.class.__send__(:define_method, :config){ config }
        self.class.__send__(:define_method, :shelf){ shelf }

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
            cmd, *args = cmd.to_s.split(/\s/).map!{|m|m.strip}
            next if cmd.nil?
            res = Commands.respond_to?(cmd)? 
              Commands.__send__(cmd, args): "Commands #{cmd} Not Defined."
              system("echo \"#{res}\" "+
                     (pipes.to_s.empty? ? '': '|'+pipes.join('|'))) unless res.to_s.empty?
          rescue Exception => e
            puts "Commands #{cmd} Failure."
            puts "#{e.class} #{e.message}"
            puts $@
          end
        end
      end

    end

  end
end
