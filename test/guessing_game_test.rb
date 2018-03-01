require_relative 'test_helper'
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

  def test_count_guesses
    game = GuessingGame.new
    game.guess(1)

    assert_equal 1, game.count

    game.guess(99)

    assert_equal 2, game.count
  end

  def test_last_guess
    game = GuessingGame.new
    game.guess(1)

    assert_equal 1, game.last_guess
  end

  def test_over_under
    game = GuessingGame.new
    game.guess(game.answer - 1)

    assert_equal 'Too Low', game.over_under

    game.guess(game.answer + 1)

    assert_equal 'Too High', game.over_under

    game.guess(game.answer)

    assert_equal 'Correct!', game.over_under
  end
end
