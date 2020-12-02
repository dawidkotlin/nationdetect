import httpclient, xmltree, htmlparser, cligen, strutils, parseutils, terminal

type
  Nationality = enum
    afghan, albanian, algerian, argentinian, australian, austrian
    bangladeshi, belgian, bolivian, botswanian, brazilian, bulgarian
    cambodian, cameroonian, canadian, chilean, chinese, colombian, croatian, cuban, czech
    danish, dominican
    ecuadorian, egyptian
    salvadorian, english, estonian, ethiopian
    fijian, finnish, french
    german, ghanaian, greek, guatemalan
    haitian, honduran, hungarian
    icelandic, indian, indonesian, iranian, iraqi, irish, israeli, italian
    jamaican, japanese, jordanian
    kenyan, kuwaiti
    lao, latvian, lebanese, libyan, lithuanian
    malagasy, malaysian, malian, maltese, mexican, mongolian, morrocan, mozambican
    namibian, nepalese
    dutch
    nicaraguan, nigerian, norwegian
    pakistani, panamanian, paraguayan, peruvian, philippine, polish, portuguese
    romanian, russian
    saudi, scottish, senegalese, serbian, singaporean, slovak
    korean
    spanish, sudanese, swedish, swiss, syrian
    taiwanese, tajikstani, thai, tongan, tunisian, turkish
    ukrainian, emirati, british, american, uruguayan, venezuelan, vietnamese, welsh, zambian, zimbabwean

var
  cache: array[Nationality, string]

for nat in Nationality:
  cache[nat] = $nat

proc main(args: seq[string], pl=false) =
  let client = newHttpClient()
  for arg in args:
    var personName, url: string
    let i = arg.rfind('/')
    if i > 0:
      url = arg
      personName = url.substr(i+1).replace("_", " ")
    else:
      personName = arg
      url = "https://" & (if pl: "pl" else: "en") & ".wikipedia.org/wiki/" & personName.replace(" ", "_")
    try:
      var score: array[Nationality, int]
      var queue = @[client.getContent(url).parseHtml()]
      while queue != @[]:
        let node = queue.pop()
        for kid in node:
          if kid.kind == xnElement:
            queue.add kid
          elif kid.kind == xnText:
            let text = kid.text
            var i = 0
            var word: string
            while i <= text.high:
              i += text.parseWhile(word, Letters, i) + 1
              word = word.toLowerAscii()
              for nat, natWord in cache:
                if natWord == word:
                  inc score[nat]
                  break
      var bestNat: Nationality
      var bestScore = 0
      for nat, score in score:
        if score > bestScore:
          bestNat = nat
          bestScore = score
      stdout.styledWriteLine(
        styleBright, personName,
        resetStyle, " is most likely ",
        styleBright, $bestNat)
    except HttpRequestError as err:
      stderr.writeLine "url = ", url 
      stderr.writeLine err.msg
      stderr.flushFile()
    except OSError as err:
      stderr.writeLine "url = ", url 
      stderr.writeLine err.msg
      stderr.flushFile()

dispatch main