; ahk: console
class AhkTags {

	requires() {
		return [Ansi, OptParser]
	}

	static author := "Klaus-Peter Schreiner"
	static email := "kpschreiner13@gmail.com"
	static url := "https://www.github.com/ghid"

	static options
	static outputFile := 0
	static tags := ""

	setDefaults() {
		AhkTags.options
				:= { help: false
				, encoding: "utf-8"
				, recurse: false
				, tagFileFormat: 2
				, tagFile: "tags"
				, sortTags: true
				, verbose: false
				, version: false }
	}

	cli() {
		op := new OptParser(["ahktags [options] [file(s) [file(s)]...]"]
				, OptParser.PARSER_ALLOW_DASHED_ARGS)
		op.add(new OptParser.Group("Options:"))
		op.add(new OptParser.Boolean("s", "sort"
				, AhkTags.options, "sortTags"
				, "Sort tag file (default: true)"
				, OptParser.OPT_NEG|OptParser.OPT_NEG_USAGE
				, AhkTags.options.sortTags))
		op.add(new OptParser.Boolean("r", "recurse"
				, AhkTags.options, "recurse"
				, "Recurse into directories"))
		op.add(new OptParser.String("f", ""
				, AhkTags.options, "tagFile", "name"
				, "Specify the name of the file to write. (Default is '"
				. AhkTags.options.tagFile "'). Use '-' to write output "
				. "to standard output instead"
				, OptParser.OPT_ARGREQ|OptParser.OPT_ALLOW_SINGLE_DASH
				, AhkTags.options.tagFile, AhkTags.options.tagFile))
		op.add(new OptParser.String("e", "encoding"
				, AhkTags.options, "encoding", "codepage"
				, "Specify the encoding of the tag file (Default is '"
				. AhkTags.options.encoding "')"
				, OptParser.OPT_ARGREQ
				, AhkTags.options.encoding, AhkTags.options.encoding))
		op.add(new OptParser.Boolean("v", "verbose"
				, AhkTags.options, "verbose"
				, "Enable verbose mode"))
		op.add(new OptParser.Boolean("h", "help"
				, AhkTags.options, "help"
				, "This help", OptParser.OPT_HIDDEN))
		op.add(new OptParser.Boolean(0, "version"
				, AhkTags.options, "version"
				, "Display version info"))
		return op
	}

	run(cmdLineArguments) {
		returnCode := ""
		AhkTags.setDefaults()
		try {
			op := AhkTags.cli()
			remainingArguments := op.parse(cmdLineArguments)
			if (remainingArguments.maxIndex() == "") {
				remainingArguments := ["*"]
			}
			if (AhkTags.options.help) {
				Ansi.writeLine(op.usage())
			} else if (AhkTags.options.version) {
				Ansi.writeLine(AhkTags.versionInfo()
						. " Copyright (C) 2019 " AhkTags.author)
			} else {
				AhkTags.findAndTagFiles(remainingArguments)
			}
		} catch gotException {
			Ansi.writeLine(gotException.message)
			Ansi.writeLine(op.usage())
			returnCode := -1
		} finally {
			AhkTags.closeOutputFile()
		}
		return returnCode
	}

	versionInfo() {
		global G_VERSION_INFO
		return G_VERSION_INFO.NAME "/" G_VERSION_INFO.ARCH
				. "-" G_VERSION_INFO.BUILD
	}

	findAndTagFiles(filePatterns) {
		loop % filePatterns.maxIndex() {
			filesToTag := AhkTags
					.determineFilesToBeTagged(filePatterns[A_Index])
			loop % filesToTag.maxIndex() {
				AhkTags.tagFile(filesToTag[A_Index])
			}
		}
		AhkTags.sortTagsIfRequested()
		AhkTags.writeTagFile()
	}

	determineFilesToBeTagged(filePattern) {
		fileNames := []
		loop files, %filePattern%, % (AhkTags.options.recurse ? "R" : "")
		{
			if (RegExMatch(A_LoopFileLongPath, "i)\.ahk$")) {
				fileNames.push(A_LoopFileLongPath)
			}
		}
		return fileNames
	}

	tagFile(fileName) {
		inputFile := FileOpen(fileName, "r")
		try {
			if (AhkTags.options.verbose) {
				Ansi.writeLine("Open " fileName)
			}
			content := inputFile.read()
			maskedContent := AhkTags.maskComments(content)
			AhkTags.searchTags(fileName, maskedContent
					, "^\s*class\s+([a-z0-9_#@$]+)"
					, 1, "mi`a", "c")
			AhkTags.searchTags(fileName, maskedContent
					, "^\s*([a-z0-9_#@$]+)\([\w\W\s\S]*?\)\s*\{"
					, 1, "mi`a", "f")
			AhkTags.searchTags(fileName, maskedContent
					, "^\s*([a-z0-9_#@$]+)::"
					, 1, "mi`a", "f")
		} finally {
			inputFile.close()
		}
	}

	searchTags(fileName, content, tagRegEx, groupNumber, regExOptions, kind) {
		startAt := 1
		regEx := regExOptions "O)" tagRegEx
		while (foundAt := RegExMatch(content, regEx, $, startAt)) {
			tagAddressStart := AhkTags.findStartOfLine(content, foundAt)
			tagAddressLength := AhkTags.findEndOfLine(content, foundAt)
					- tagAddressStart
			tagAddress := "/^"
					. SubStr(content, tagAddressStart, tagAddressLength)
					. "$/"
			AhkTags.addTag($.Value(groupNumber), fileName, tagAddress, kind)
			startAt := ($.Pos(groupNumber) + $.Len(groupNumber))
		}
	}

	findStartOfLine(text, currentPosition) {
		startOfLineAt := currentPosition
		loop {
			startOfLineAt--
		} until (InStr("`n`r", SubStr(text, startOfLineAt, 1)) > 0
				|| startOfLineAt == 0)
		return startOfLineAt + 1
	}

	findEndOfLine(text, currentPosition) {
		endOfLineAt := currentPosition + 1
		loop {
			endOfLineAt++
		} until (InStr("`n`r", SubStr(text, endOfLineAt, 1)) > 0
				|| endOfLineAt == StrLen(text))
		return endOfLineAt
	}

	addTag(tagName, tagFile, tagAddress, tagFields="") {
		tagAddress := RegExReplace(tagAddress, "[\r\n]+", "\n")
		tagAddress := (SubStr(tagAddress, 1, 4) == "/^\n"
				? "/^" SubStr(tagAddress, 5)
				: tagAddress)
		tagLine := tagname "`t" tagFile "`t"
				. tagAddress
				. (tagFields != "" && AhkTags.options.tagFileFormat == 2
				? ";""`t" tagFields
				: "")
		AhkTags.tags .= tagLine "`n"
	}

	addTagFileHeaders() {
		headers := "!_TAG_FILE_FORMAT`t" AhkTags.options.tagFileFormat "`n"
				. "!_TAG_FILE_SORTED`t" AhkTags.options.sortTags "`n"
				. "!_TAG_FILE_ENCODING`t" AhkTags.options.encoding "`n"
				. "!_TAG_FILE_PROGRAM`t" A_ScriptName "`n"
				. "!_TAG_FILE_VERSION`t" AhkTags.versionInfo() "`n"
				. "!_TAG_FILE_URL`t" AhkTags.url "`n"
				. "!_TAG_FILE_AUTHOR`t" AhkTags.author "`t/" AhkTags.email "`n"
		AhkTags.tags := headers . AhkTags.tags
	}

	maskComments(content) {
		startAt := 1
		while (foundAt := RegExMatch(content
				, "ms`a)(?<=\/\*)(.*?)(?=\*\/)|(`;.*?$)"
				, comment, startAt)) {
			content := SubStr(content, 1, foundAt - 1)
					. RegExReplace(comment, "\w", "X")
					. SubStr(content, foundAt + StrLen(comment))
			startAt := foundAt + StrLen(comment) + 1
		}
		return content
	}

	verboseOutput(message) {
		if (AhkTags.options.verbose) {
			Ansi.writeLine(message)
		}
	}

	sortTagsIfRequested() {
		tags := AhkTags.tags
		if (AhkTags.options.sortTags) {
			AhkTags.verboseOutput("Sort tags")
			Sort tags
		}
		AhkTags.tags := tags
	}

	writeTagFile() {
		if (AhkTags.options.tagFile != "-") {
			AhkTags.addTagFileHeaders()
		}
		AhkTags.openOutputFile()
		AhkTags.outputFile.write(AhkTags.tags)
		AhkTags.outputFile.close()
	}

	openOutputFile() {
		if (AhkTags.options.tagFile == "-") {
			AhkTags.verboseOutput("Using standard out")
			AhkTags.outputFile := FileOpen("*", "w")
		} else {
			AhkTags.verboseOutput("Write to file " AhkTags.options.tagFile)
			AhkTags.verboseOutput("Using encoding " AhkTags.options.encoding)
			AhkTags.outputFile := FileOpen(AhkTags.options.tagFile, "w"
					, AhkTags.options.encoding)
		}
	}

	closeOutputFile() {
		AhkTags.outputFile.close()
	}

}

#NoEnv ; notest-begin
#NoTrayIcon
#SingleInstance Off
ListLines Off
SetBatchLines -1

#Include <ansi>
#Include <optparser>
#Include <string>
#Include <object>
#Include *i %A_ScriptDir%\.versioninfo

main:
	Ansi.NO_BUFFER := true
exitapp AhkTags.run(A_Args) ; notest-end
