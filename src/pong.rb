require("ruby2d")

set background: 'black'

set width: 786

PONG_SOUND = Sound.new('sfx/ballHit.wav')
PING_SOUND = Sound.new('sfx/ballHit2.wav')
BALL_RESET = Sound.new('sfx/ballReset.wav')

class Score

  def initialize(player1, enemy)
    @Player_Score = player1
    @Enemy_Score = enemy
  end

  def draw

    Text.new(
      @Player_Score,
      x: Window.width/2-100, y: 30,
      style: 'bold',
      size: 20,
      color: 'white',
      z: 10
    )
    Text.new(
      @Enemy_Score,
      x: Window.width/2+100, y: 30,
      style: 'bold',
      size: 20,
      color: 'white',
      z: 10
    )

  end

  def score_for_player
    @Player_Score += 1
  end

  def score_for_enemy
    @Enemy_Score += 1
  end

end

class NextCoordinates
  def initialize(x, y, x_velocity, y_velocity)
    @x = x
    @y = y
    @X_velocity = x_velocity
    @Y_velocity = y_velocity
  end

  def x
    @x + (@X_velocity * [x_length, y_length].min)
  end

  def y
    @y + (@Y_velocity * [x_length, y_length].min)
  end

  def hit_top_or_bottom?
    x_length > y_length
  end

  private 

  def x_length
    if @X_velocity > 0
      (Window.width - 60 - @x) / @X_velocity
    else
      (@x - 60) / (-@X_velocity)
    end
  end

  def y_length
    if @Y_velocity > 0
      (Window.height - @y) / @Y_velocity
    else
      (@y) / (-@Y_velocity)
    end
  end



end

class BallTrajectory

  def initialize(ball)
    @ball = ball
  end

  def draw
    next_coords = NextCoordinates.new(@ball.x_middle, @ball.y_middle, @ball.x_velocity, @ball.y_velocity)
    line = Line.new(x1: @ball.x_middle, y1: @ball.y_middle, x2: next_coords.x , y2: next_coords.y, color:'red', opacity: 0)
    if next_coords.hit_top_or_bottom?
      final_coords = NextCoordinates.new(next_coords.x, next_coords.y, @ball.x_velocity, -@ball.y_velocity)
      Line.new(x1: next_coords.x, y1: next_coords.y, x2: final_coords.x , y2: final_coords.y, color:'red', opacity: 0)
    else
      line
    end
  end

  def y_middle
    draw.y2
  end


end


class DividingLine
  WIDTH = 10
  HEIGHT = 25
  NUMBER_OF_LINES = 8

  def draw
    NUMBER_OF_LINES.times do |i|
      Rectangle.new(color: 'white', x: (Window.width+WIDTH)/2, y: (Window.height / NUMBER_OF_LINES) * i, height: HEIGHT, width: WIDTH)
    end

  end

end

class Paddle
  HEIGHT = 150
  JITTER_CORRECTION = 4

  ENEMY_MOVE_DELAY_FRAMES = 60

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
      @PosX = Window.width-60
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

  def automove(ball_trajectory, last_hit_frame)

    if last_hit_frame + ENEMY_MOVE_DELAY_FRAMES < Window.frames
      if ball_trajectory.y_middle > y_middle + JITTER_CORRECTION
        @PosY += @move_speed
      elsif ball_trajectory.y_middle < y_middle -  JITTER_CORRECTION
        @PosY -= @move_speed  
      end
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
  attr_reader :shape, :speed, :x_velocity, :y_velocity, :PosX

  def initialize(speed)
    @speed = speed
    
    @PosX = Window.width/2
    @PosY = Window.height/2

    @y_velocity = [-speed, speed].sample
    @x_velocity = [-speed, speed].sample
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

  def x_middle 
    @PosX + (SIZE / 2)
  end

  def out_of_bounds?
    @PosX <= 0 || @shape.x2 >= Window.width
  end

  def gainSpeed
    @speed += 0.2
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
enemy = Paddle.new(:right, 3.5)

score = Score.new(0,0)

ball = Ball.new(8)
ball_trajectory = BallTrajectory.new(ball)


bgm = Music.new('bgm/Lines of Code.mp3')
bgm.loop = true
bgm.play

last_hit_frame = 0


# MAIN GAME LOOP
update do
  clear

  DividingLine.new.draw

  if player.hit_ball?(ball)
    ball.bounce_off(player)
    PONG_SOUND.play
    ball.gainSpeed()
    last_hit_frame = Window.frames
  end

  if enemy.hit_ball?(ball)
    ball.bounce_off(enemy)
    PONG_SOUND.play
    ball.gainSpeed()
    last_hit_frame = Window.frames
  end

  player.move
  player.draw

  ball.move
  ball.draw

  ball_trajectory.draw

  enemy.automove(ball_trajectory, last_hit_frame)
  enemy.draw

  score.draw

  if ball.out_of_bounds?

    if ball.PosX <= Window.width/2
      score.score_for_enemy
    else
      score.score_for_player
    end

    ball = Ball.new(8)
    ball_trajectory = BallTrajectory.new(ball)
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