require("ruby2d")

set background: 'black'

PONG_SOUND = Sound.new('sfx/ballHit.wav')
PING_SOUND = Sound.new('sfx/ballHit2.wav')

BALL_RESET = Sound.new('sfx/ballReset.wav')

class Paddle
  HEIGHT = 150
  JITTER_CORRECTION = 4
  attr_writer :direction

  attr_reader :side

  def initialize(side, speed)
    @side = side
    @move_speed = speed
    @direction = nil
    @PosY = 200
    if side == :left
      @PosX = 40
    else
      @PosX = 600
    end
  end

  def move
    if @direction == :up
      @PosY = [@PosY - @move_speed,0].max
    elsif @direction == :down
      @PosY = [@PosY + @move_speed, max_y].min
    end
  end

  def draw
    @shape = Rectangle.new(x: @PosX, y: @PosY, width: 20, height: HEIGHT, color: 'white')
  end

  def hit_ball?(ball)
    ball.shape && [[ball.shape.x1, ball.shape.y1], [ball.shape.x2, ball.shape.y2],
     [ball.shape.x3, ball.shape.y3], [ball.shape.x4, ball.shape.y4]].any? do |coordinates|
      @shape.contains?(coordinates[0], coordinates[1])
    end
  end

  def automove(ball)
    if ball.y_middle > y_middle + JITTER_CORRECTION
      @PosY += @move_speed
    elsif ball.y_middle < y_middle -  JITTER_CORRECTION
      @PosY -= @move_speed  
    end
  end

  def y1
    @shape.y1
  end



  private

  def y_middle
    @PosY + (HEIGHT / 2)
  end

  def max_y
    Window.height - HEIGHT
  end

end

class Ball
  SIZE = 25
  attr_reader :shape
  attr_reader :speed
  def initialize(speed)
    @speed = speed
    
    @PosX = Window.width/2
    @PosY = Window.height/2

    @y_velocity = speed
    @x_velocity = -speed
  end

  def draw
    @shape = Square.new(x: @PosX, y: @PosY, size: SIZE, color: 'white')
  end

  def move
    if hit_bottom? || hit_top?
      @y_velocity = @y_velocity * -1
      PING_SOUND.play
    end

      @PosX = @PosX + @x_velocity
      @PosY = @PosY + @y_velocity 
  
  end

  def bounce_off(paddle)
    if @last_hit_side != paddle.side

      position = (@shape.y1 - paddle.y1) / Paddle::HEIGHT.to_f
      angle = position.clamp(0.2, 0.8) * Math::PI

      # puts "position: #{position}"

      if paddle.side == :left
        @x_velocity = Math.sin(angle) * @speed
        @y_velocity = -Math.cos(angle) * @speed
      end

      if paddle.side == :right
        @x_velocity = -Math.sin(angle) * @speed
        @y_velocity = -Math.cos(angle) * @speed
      end

      @last_hit_side = paddle.side
    end
  end

  def y_middle
    @PosY + (SIZE / 2)
  end


  def out_of_bounds?
    @PosX <= 0 || @shape.x2 >= Window.width
  end

  def gainSpeed
    @speed += 1
  end

  private 

  def hit_bottom?
     @PosY + SIZE >= Window.height
  end

  def hit_top?
    @PosY <= 0
  end



end

player = Paddle.new(:left, 5)
enemy = Paddle.new(:right, 5)

ball = Ball.new(8)

bgm = Music.new('bgm/Lines of Code.mp3')
bgm.loop = true
bgm.play

# MAIN GAME LOOP
update do
  clear

  if player.hit_ball?(ball)
    ball.bounce_off(player)
    PONG_SOUND.play
    ball.gainSpeed()
  end

  if enemy.hit_ball?(ball)
    ball.bounce_off(enemy)
    PONG_SOUND.play
    ball.gainSpeed()
  end

  ball.move
  ball.draw

  player.move
  player.draw

  enemy.automove(ball)
  enemy.draw

  if ball.out_of_bounds?
    ball = Ball.new(8)
    BALL_RESET.play
  end

end


on :key_held do |event|
  if event.key == 'up'
    player.direction = :up
  elsif event.key == 'down'
    player.direction = :down
  end
end

on :key_up do |event|
  player.direction = nil
end



show