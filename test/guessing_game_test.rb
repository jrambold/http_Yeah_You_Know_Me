require 'minitest/autorun'
require 'minitest/pride'
require './lib/guessing_game'

# test for guessing_game
class GuessingGameTest < Minitest::Test
  def test_makes_random_answer
    game = GuessingGame.new

    assert (0..100).to_a.include?(game.answer)
  end

  def test_can_make_guess
    game = GuessingGame.new

    game.guess(game.answer + 1)

    refute game.correct?

    game.guess(game.answer)

    assert game.correct?
  end
end
