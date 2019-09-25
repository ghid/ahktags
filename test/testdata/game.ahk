; ahk: console
#NoEnv ; NOTEST-BEGIN
#Warn All, StdOut

#Include <ansi>
#Include <console>
#Include <flimsydata>
#Include <random>
#Include <calendar>
#Include <string>
#Include <arrays>

#Include %A_ScriptDir%\modules\player.ahk

Main:
	loop 3 {
		Game.registerPlayer(new Player())
	}
	Game.play()
exitapp ; NOTEST-END

class Game {

	requires() {
		return [Ansi, Player, String]
	}

	static roundsToPlay := 10
	static numberOfMatches := 3
	static sumOfDrawnMatches := 0
	static players := []
	static guesses := {}

	registerPlayer(newPlayer) {
		Game.players.push(newPlayer)
	}

	play() {
		Ansi.writeLine(Game.players.maxIndex() " players")
		loop % Game.roundsToPlay {
			roundNumber := A_Index
			Game.sumOfDrawnMatches := 0
			Ansi.writeLine()
			Ansi.writeLine("Round " roundNumber)
			Ansi.writeLine()
			Game.drawPhase()
			Ansi.writeLine()
			Game.guessPhase()
			Ansi.writeLine()
			Game.checkResults()
		}
		Ansi.writeLine()
		Game.findWinners()
		Ansi.writeLine()
	}

	drawPhase() {
		loop {
			playerNumber := A_Index
			currentPlayer := Game.players[playerNumber]
			currentPlayer.draw()
			Ansi.writeLine("%s draws %i".printf(currentPlayer.name
					, currentPlayer.draws))
			Game.sumOfDrawnMatches += currentPlayer.draws
		} until (playerNumber >= Game.players.maxIndex())
	}

	guessPhase() {
		static playerToGuess := 1

		Game.commitedGuesses := {}
		while (A_Index <= Game.players.maxIndex()) {
			currentPlayer := Game.players[playerToGuess]
			soleGuess := false
			loop {
				try {
					soleGuess := currentPlayer.guess()
					Game.commitedGuesses[currentPlayer.guesses]
							:= currentPlayer.name
				} catch gotException {
					Ansi.writeLine(gotException.message)
					Ansi.writeLine("%s guesses again..."
							.printf(currentPlayer.name))
				}
			} until (soleGuess == true)
			Ansi.writeLine("%s guesses %i...".printf(currentPlayer.name
					, currentPlayer.guesses))
			Game.guesses[playerToGuess] := currentPlayer.guesses
			if (playerToGuess < Game.players.maxIndex()) {
				playerToGuess++
			} else {
				playerToGuess := 1
			}
		}
	}

	checkResults() {
		for playerNumber, guess in Game.guesses {
			if (guess == Game.sumOfDrawnMatches) {
				currentPlayer := Game.players[playerNumber]
				Ansi.writeLine("%s has guessed right. He's getting 1 point!"
						.printf(currentPlayer.name))
				currentPlayer.guessWasGood()
				return
			}
		}
		Ansi.writeLine("No player guessed right.")
	}

	findWinners() {
		loop % Game.players.maxIndex() {
			currentPlayer := Game.players[A_Index]
			Ansi.writeLine("%s has %i correct guesses."
					.printf(currentPlayer.name, currentPlayer.goodGuesses))
		}
	}
}
