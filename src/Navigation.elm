module Navigation exposing (Route(..), pushRoute, toRoute)

import Browser.Navigation exposing (Key, pushUrl)
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


pushRoute : Key -> Route -> Cmd msg
pushRoute key r =
    pushUrl key <|
        case r of
            Home ->
                "/"

            Problem ->
                "/problem"

            NotFound ->
                "/404"
