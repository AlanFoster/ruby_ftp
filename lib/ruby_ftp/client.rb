require 'socket'

module RubyFtp
  class Client
    attr_reader :host, :port

    COMMAND_OKAY = 200
    HELP_MESSAGE = 214
    USER_LOGGED_IN_PROCEED = 230
    USER_NAME_OKAY_NEED_PASSWORD = 331
    NOT_LOGGED_IN = 530

    def initialize(host: nil, port: 21)
      @host = host
      @port = port
    end

    def banner
      return @banner if @banner

      # side effect?
      command_socket
      @banner
    end

    # Login in with the given username and password, anonymous login by default
    def login(username: 'anonymous', password: nil)
      write_command("USER #{username}")
      write_command("PASS #{password}")
    end

    # Print the current working directory
    def pwd
      write_command('PWD')
    end

    # List the current files, defaults to PASV mode
    def ls
      write_data_command('LIST')
    end

    # Show the available commands
    def help
      write_command('HELP')
    end

    # Buffer a file and print it
    def cat(filename)
      write_data_command("RETR #{filename}")
    end

    # Close the ftp client and associated sockets
    def close
      close_socket(@command_socket)
      @command_socket = nil

      close_socket(@data_socket)
      @data_socket = nil
    end

    private

    # Close the given socket
    def close_socket(socket)
      return unless socket

      begin
        socket.close
      rescue IOError => _e
        # noop
      end
    end

    # Write the given command to the command to the socket. FTP requires both a command socket, and a data socket
    def write_command(command)
      command_socket.write("#{command}\n")
      read_command_response(command_socket)
    end

    # From the specs:
    # A single line reply will begin with `3_digit_code<whitespace>`
    # A multi-line reply will begin with `3_digit_code<hyphen>` and end with`3_digit_code<whitespace>`
    # For example:
    #   123-First line
    #   Second line
    #     234 A line beginning with numbers
    #   123 The last line
    def read_command_response(socket)
      result = ''

      # Read until the end of the command data, such as "226 Directory send OK.\r\n"
      while (line = socket.gets)
        result += line
        break if line =~ /^(\d+) /
      end

      result
    end

    # Returns the currently opened command socket, or creates a new socket if one does not exist
    def command_socket
      return @command_socket if defined?(@command_socket)

      @command_socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM)
      @command_socket.connect Socket.pack_sockaddr_in(port, host)

      @banner = @command_socket.gets

      @command_socket
    end

    # Opens a new connection to the data socket after entering PASV mode
    # Then we send the required command, block reading from the data channel,
    def write_data_command(cmd)
      result = ''

      response = write_command('PASV')
      success_regex = /227 Entering Passive Mode \((?<ip1>\d+),(?<ip2>\d+),(?<ip3>\d+),(?<ip4>\d+),(?<port1>\d+),(?<port2>\d+)\)\.\r\n/
      if (match = success_regex.match(response))
        # Doesn't work with Docker + Mac, cheating for now
        # data_ip = "#{match[:ip1]}.#{match[:ip2]}.#{match[:ip3]}.#{match[:ip4]}"
        data_ip = '127.0.0.1'
        data_port = (match[:port1].to_i << 8) + match[:port2].to_i

        @data_socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
        # Connect non-blocking - the error means it's successful?
        begin
          @data_socket.connect_nonblock Socket.pack_sockaddr_in(data_port, data_ip)
        rescue IO::WaitWritable
          # This exception means it was successful

          res = write_command(cmd)
          puts res

          # Block waiting for an async read
          IO.select(nil, [@data_socket])

          result = ''
          while (line = @data_socket.gets)
            result += line
          end

          close_socket(@data_socket)

          command_response = read_command_response(command_socket)
          puts command_response
        end
      end

      result
    end

  end
end
