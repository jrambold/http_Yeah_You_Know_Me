# Guessing between 0 to 100 game
class GuessingGame
  attr_reader :answer,
              :count,
              :last_guess

  def initialize
    @answer = Random.new.rand(101)
    @guess = nil
    @count = 0
  end

  def guess(value)
    @count += 1
    @last_guess = value
  end

  def over_under
    if @answer > @last_guess
      'Too Low'
    elsif @answer < @last_guess
      'Too High'
    else
      'Correct!'
    end
  end

  def correct?
    @last_guess == @answer
  end
end
