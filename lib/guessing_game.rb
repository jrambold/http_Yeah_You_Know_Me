class GuessingGame
  attr_reader :answer,
              :count

  def initialize
    @answer = Random.new.rand(101)
    @guess = nil
    @count = 0
  end

  def guess(value)
    @count += 1
    @guess = value
    if @answer > @guess
      'Too Low'
    elsif @answer < @guess
      'Too High'
    else
      'Correct!'
    end
  end

  def correct?
    @guess == @answer
  end
end
