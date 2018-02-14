class GuessingGame
  attr_reader :answer

  def initialize
    @answer = Random.new.rand(101)
    @guess = nil
  end

  def guess(value)
    @guess = value
  end

  def correct?
    @guess == @answer
  end
end
