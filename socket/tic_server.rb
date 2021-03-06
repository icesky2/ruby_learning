require 'socket'

class Cell

  attr_accessor :value

  def initialize(value = "N")
    @value = value
    @enable = true
  end

  def set_value(value)
    @value = value
  end

  def set_enable(enable)
    @enable = enable
  end

  def get_enable
    @enable
  end
end

class Board

  attr_reader :grid

  def initialize(grid = default_grid)
    @grid = grid
    set_position
  end

  def get_cell(x, y)
    @grid[x][y]
  end

  def set_cell(x, y, value)
    get_cell(x, y).set_value value
    get_cell(x, y).set_enable false
  end

  def default_grid
    3.times.map do 
      3.times.map do
        Cell.new
      end
    end
    #Array.new(3) { Array.new(3) { Cell.new } }
  end

  def set_position
    position = 1
    (0..2).each do |i|
      (0..2).each do |j|
        get_cell(i, j).set_value position.to_s 
        position+=1
      end
    end 
  end
end

def clients_puts(message)
  @client[0].puts message
  @client[1].puts message
end

def clients_board
  str = ""
  (0..2).each do |i|
    (0..2).each do |j|
      str += "#{@board.get_cell(i, j).value} "
    end
  end
  str
end

#class Play

  def check_winner(player)
    #check all rows
    (0..2).each do |i|
      if ((@board.get_cell(i, 0).value == player) and
          (@board.get_cell(i, 1).value == player) and
          (@board.get_cell(i, 2).value == player))
         return player
      end
    end

    #check all columns
    (0..2).each do |j|
      if ((@board.get_cell(0, j).value == player) and
          (@board.get_cell(1, j).value == player) and
          (@board.get_cell(2, j).value == player))
         return player
      end
    end
       
    #check main diagonal
    if ((@board.get_cell(0, 0).value == player) and
        (@board.get_cell(1, 1).value == player) and
        (@board.get_cell(2, 2).value == player))
       return player
    end

    #check subdiagonal
    if ((@board.get_cell(0, 2).value == player) and
        (@board.get_cell(1, 1).value == player) and
        (@board.get_cell(2, 0).value == player))
       return player
    end

    return 'continue'
  end

  def get_move(player)
    client_number = player == 'o' ? 0 : 1
    @client[client_number].puts "REQ"
    return @client[client_number].gets
  end

  def set_move(player, position)
    puts "Player #{player} set move on: #{position}"
    position -= 1
    @board.set_cell position/3, position%3, player
  end
#end

@board = Board.new
@client = []
server = TCPServer.open(2000)  # Socket to listen on port 2000
@client[0] = server.accept
puts "Player o joined session #{Time.now}"
@client[0].puts "PNT Hello Player o. Wait for Player x."

@client[1] = server.accept
@client[1].puts "PNT Hello Player x"
puts "Player x joined session #{Time.now}"

clients_puts "PNT Alright both players connected"
current_player = 'o'
(1..9).each do |turn_number|
  clients_puts "CLR"
  clients_puts "PNT Turn #{turn_number}: Player #{current_player}"
  clients_puts "BRD #{clients_board}"
  player_move = (get_move current_player).to_i

  while(@board.get_cell((player_move-1)/3, (player_move-1)%3).get_enable == false)
    if (current_player == 'o')
      @client[0].puts "PNT The position has already been changed. Input again!!"
    elsif (current_player == 'x')
      @client[1].puts "PNT The position has already been changed. Input again!!"
    end
    player_move = (get_move current_player).to_i
  end

  set_move current_player, player_move
  if check_winner(current_player) != 'continue'
     break
  end
  current_player = current_player == 'o' ? 'x' : 'o'
end

clients_puts "CLR"
clients_puts "BRD #{clients_board}"
if check_winner(current_player) == 'continue'
   clients_puts "PNT Draw Game!!"
else
   clients_puts "PNT Winner: #{check_winner current_player}"
end
clients_puts "QUIT"
@client[0].close                 # Disconnect from the client
puts "Player o left session #{Time.now}"
@client[1].close                 # Disconnect from the client
puts "Player x left session #{Time.now}"
