class Player {

	seed := 0
	name := ""
	randomGenerator := {}
	matchesDrawn := 0
	goodGuesses := 0
	draws := 0
	guesses := 0

	requires() {
		return [FlimsyData, Random]
	}

	__new(name="", seed=606) {
		this.seed := seed
		if (name != "") {
			this.name := name
		} else {
			this.name := this.generatePlayersName()
		}
		this.randomGenerator := new FlimsyData.Simple(this.seed)
		return this
	}

	generatePlayersName() {
		numberOfPlayersSoFar := Game.players.maxIndex()
		return "Player" (numberOfPlayersSoFar == ""
				? 1
				: numberOfPlayersSoFar + 1)
	}

	draw() {
		this.draws := this.randomGenerator.getInt(0, Game.numberOfMatches)
	}

	guess() {
		this.guesses := this.randomGenerator.getInt(0
				, Game.numberOfMatches * Game.players.maxIndex())
		if (Game.commitedGuesses.hasKey(this.guesses)) {
			playerWhoCommittedTheGuessAlready
					:= Game.commitedGuesses[this.guesses]
					throw Exception(("Oops, %s wants to guess %i, "
							. "but this was already guessed by %s...")
							.printf(this.name, this.guesses
							, playerWhoCommittedTheGuessAlready))
		}
		return true
	}

	guessWasGood() {
		this.goodGuesses++
	}
}
