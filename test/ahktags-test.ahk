; ahk: console
#NoEnv
#Warn All, StdOut

#Include <testcase-libs>

class AhkTagsTest extends TestCase {

	requires() {
		return [TestCase, AhkTags]
	}

	@Before_resetOptions() {
		AhkTags.setDefaults()
	}

	@Test_maskLineComments() {
		this.assertEquals(AhkTags
				.maskComments("    if (x == 1) { `; Test if x is equal one")
				, "    if (x == 1) { `; XXXX XX X XX XXXXX XXX")
		this.assertEquals(AhkTags
				.maskComments(TestCase.fileContent(A_ScriptDir
				. "\testdata\CodeWithComments.txt"))
				, TestCase.fileContent(A_ScriptDir
				. "\figures\CodeWithMaskedComments.txt"))
	}

	@Test_findStartOfLine() {
		this.assertEquals(AhkTags.findStartOfLine("abc`n"
				. "    if (x == 0) {`n"
				. "        x++`n"
				. "    }", 9), 5)
		this.assertEquals(AhkTags.findStartOfLine("    if (x == 0) {`n"
				. "        x++`n"
				. "    }", 9), 1)
		this.assertEquals(AhkTags.findStartOfLine("    if (x == 0) {`n"
				. "        x++`n"
				. "    }", 1), 1)
	}

	@Test_findEndOfLine() {
		this.assertEquals(AhkTags.findEndOfLine("abc`n"
				. "    if (x == 0) {`n"
				. "        x++`n"
				. "    }", 9), 22)
		this.assertEquals(AhkTags.findEndOfLine("    if (x == 0) {`n"
				. "        x++`n"
				. "    }", 9), 18)
		this.assertEquals(AhkTags.findEndOfLine("    if (x == 0) {`n"
				. "        x++`n"
				. "    }", 34), 36)
	}

	@Test_determineFiles() {
		fileNames := AhkTags.determineFilesToBeTagged(A_ScriptDir
				. "\testdata\*")
		this.assertEquals(fileNames.maxIndex(), 1)
		this.assertEquals(fileNames[1]
				, A_ScriptDir "\testdata\game.ahk")
	}

	@Test_determineFilesRecursive() {
		AhkTags.options.recurse := true
		fileNames := AhkTags.determineFilesToBeTagged(A_ScriptDir
				. "\testdata\*")
		this.assertEquals(fileNames.maxIndex(), 2)
		this.assertEquals(fileNames[1]
				, A_ScriptDir "\testdata\game.ahk")
		this.assertEquals(fileNames[2]
				, A_ScriptDir "\testdata\modules\Player.ahk")
	}
}

exitapp AhkTagsTest.runTests()

#Include %A_ScriptDir%\..\ahktags.ahk
