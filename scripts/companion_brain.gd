extends RefCounted
class_name CompanionBrain

var companion_name := "Mira"
var relation := 5
var mood := "ostrożna"
var memories: Array[String] = []

func remember(event: String) -> void:
    if not memories.has(event):
        memories.append(event)

func react(context: String) -> String:
    match context:
        "storm_tavern":
            if memories.has("spotted_tracks"):
                return "Te ślady nie prowadzą do karczmy przypadkiem. Ktoś tu wszedł niedawno i próbował to ukryć."
            return "Nie podoba mi się ta cisza. Karczma świeci, a nikt nie wychodzi mimo burzy. Trzymaj rękę blisko broni."
        "failed_persuasion":
            return "Świetnie. Obraziłeś człowieka, zanim zdążyliśmy wejść pod dach. Imponujące."
        "passed_persuasion":
            relation += 1
            remember("keeper_let_us_in")
            return "Dobra robota. Ciepły ogień brzmi teraz lepiej niż kolejny test charakteru na deszczu."
        _:
            return "Jestem z tobą. Ale najpierw rozejrzyjmy się, zanim zrobimy coś głupiego."
