module Navigation exposing (pushRoute, toRoute)

import Browser.Navigation exposing (Key, pushUrl)
import Types exposing (..)
import Url exposing (Url)
import Url.Parser exposing ((</>), Parser, map, oneOf, parse, s, top)


route : Parser (Route -> a) a
route =
    oneOf
        [ map Home top
        , map (ProblemPage Trivial) (s "problem" </> s "trivial")
        , map (ProblemPage Easy) (s "problem" </> s "easy")
        , map (ProblemPage Medium) (s "problem" </> s "medium")
        , map (ProblemPage Hard) (s "problem" </> s "hard")
        , map (ProblemPage Impossible) (s "problem" </> s "impossible")
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

            ProblemPage difficulty ->
                "/problem/"
                    ++ (case difficulty of
                            Trivial ->
                                "trivial"

                            Easy ->
                                "easy"

                            Medium ->
                                "medium"

                            Hard ->
                                "hard"

                            Impossible ->
                                "impossible"
                       )

            NotFound ->
                "/404"
