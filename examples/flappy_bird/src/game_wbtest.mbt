///|
test "update: title to playing on any key press" {
  let game = Game::new()
  game.game_mode.set(0)
  let empty_input = @core.empty_input_snapshot()
  game.update(empty_input)
  inspect(game.game_mode.get(), content="0")
  let input_with_key = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [13])
  game.update(input_with_key)
  inspect(game.game_mode.get(), content="1")
  assert_true(game.velocity < 0.0)
}

///|
test "update: playing jump on key press" {
  let game = Game::new()
  game.game_mode.set(1)
  game.bird_y.set(100.0)
  game.velocity = 2.0
  let empty_input = @core.empty_input_snapshot()
  game.update(empty_input)
  let input_with_space = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [32])
  game.update(input_with_space)
  assert_true(game.velocity < 0.0)
}

///|
test "update: gameover to title on action" {
  let game = Game::new()
  game.game_mode.set(2)
  game.score.set(5)
  game.pipes.set([{ x: 100.0, gap_y: 80.0 }])
  let empty_input = @core.empty_input_snapshot()
  game.update(empty_input)
  inspect(game.game_mode.get(), content="2")
  let input_with_key = @core.new_input_snapshot(0.0, 0.0, 0.0, 0.0, [32])
  game.update(input_with_key)
  inspect(game.game_mode.get(), content="0")
  inspect(game.score.get(), content="0")
  inspect(game.pipes.get().length(), content="0")
}

///|
test "update: gravity applies" {
  let game = Game::new()
  game.game_mode.set(1)
  game.bird_y.set(100.0)
  game.velocity = 0.0
  let empty_input = @core.empty_input_snapshot()
  game.update(empty_input)
  assert_true(game.velocity > 0.0)
  assert_true(game.bird_y.get() > 100.0)
  inspect(game.pipe_timer, content="1")
}

///|
test "update: pipe generation at interval" {
  let game = Game::new()
  game.game_mode.set(1)
  game.bird_y.set(100.0)
  game.pipe_timer = 119
  let empty_input = @core.empty_input_snapshot()
  game.update(empty_input)
  inspect(game.pipes.get().length(), content="1")
  assert_true((game.pipes.get()[0].x - 318.5).abs() < 0.01)
  inspect(game.pipe_timer, content="0")
}

///|
test "update: pipe movement" {
  let game = Game::new()
  game.game_mode.set(1)
  game.bird_y.set(100.0)
  game.pipes.set([{ x: 200.0, gap_y: 80.0 }])
  let empty_input = @core.empty_input_snapshot()
  game.update(empty_input)
  assert_true((game.pipes.get()[0].x - 198.5).abs() < 0.01)
}
