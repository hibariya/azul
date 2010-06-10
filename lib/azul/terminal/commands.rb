module Azul
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
          Terminal.change_editing_mode Terminal.config.editing_mode || 'emacs'
          Terminal.change_color Terminal.config.color || 0
          nil
        end

        def updatedb(args=nil)
          Terminal.shelf.reload
          nil end

        def help(args=nil)
          File.open(README){|f| f.read } end

        def execute(args)
          system("#{args.first}"); nil end

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

  end
end


