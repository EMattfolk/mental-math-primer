module Navigation exposing (Route(..), toRoute)

import Url exposing (Url)
import Url.Parser exposing (Parser, map, oneOf, parse, s, top)


type Route
    = Home
    | Problem
    | NotFound


route : Parser (Route -> a) a
route =
    oneOf
        [ map Home top
        , map Problem (s "problem")
        ]


toRoute : Url -> Route
toRoute url =
    parse route url
        |> Maybe.withDefault NotFound
