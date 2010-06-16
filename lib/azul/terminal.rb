module Azul
  class Terminal
    CONF_FILE = File.join(LOCAL_FILES_DIR, 'config')

    __here = File.dirname __FILE__
    require File.join __here, 'terminal', 'commands'

    class << self
      def change_color(c)
        print "\e[0m\e[#{c}m" end

      def change_editing_mode(e)
        Readline.__send__("#{e}_editing_mode") end

      #
      # プロンプトを開始
      #
      def ready
        config, shelf = Config.new, Shelf.new
        shelf.config = config
        self.class.__send__(:define_method, :config){ config }
        self.class.__send__(:define_method, :shelf){ shelf }
        load CONF_FILE if File.exist? CONF_FILE
        shelf.load

        change_editing_mode config.editing_mode
        change_color config.color
        Readline.completion_proc = lambda do |word|
          (Commands.methods-methods).
            grep(/\A#{Regexp.quote word}/)
        end

        puts "[#{APP_NAME} Version #{VERSION}]"
        while buf = Readline.readline("#{APP_NAME}> ", true)
          begin
            cmd, *pipes = buf.to_s.split(/\|/).map!{|m|m.strip}
            cmd, *args = cmd.to_s.split(/\s/).inject([]){|r,c|c.empty?? r: r<<c.strip}
            next if cmd.nil?
            cmd = 'execute' if cmd=='!'
            res = Commands.__send__(cmd, args) 
            resfile = File.join(config.cache_dir, '.cache')
            File.open(resfile, 'w'){|f| f.puts res }
            system("cat #{resfile} "+
                   (pipes.to_s.empty?? '': '|'+pipes.join('|'))) unless res.to_s.empty?
          rescue NoMethodError => e
            puts "Command #{cmd} not defined."
            puts "raised: #{e.class} #{e.message}"
            puts $@
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
