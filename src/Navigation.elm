module Navigation exposing (pushRoute, toRoute)

import Browser.Navigation exposing (Key, pushUrl)
import Types exposing (..)
import Url exposing (Url)
import Url.Parser exposing ((</>), Parser, map, oneOf, parse, s, top)


route : Parser (Route -> a) a
route =
    oneOf
        [ map Home top
        , map (ProblemPage AddSub Trivial) (s "addition" </> s "trivial")
        , map (ProblemPage AddSub Easy) (s "addition" </> s "easy")
        , map (ProblemPage AddSub Medium) (s "addition" </> s "medium")
        , map (ProblemPage AddSub Hard) (s "addition" </> s "hard")
        , map (ProblemPage AddSub Impossible) (s "addition" </> s "impossible")
        , map (ProblemPage Mul Trivial) (s "multiplication" </> s "trivial")
        , map (ProblemPage Mul Easy) (s "multiplication" </> s "easy")
        , map (ProblemPage Mul Medium) (s "multiplication" </> s "medium")
        , map (ProblemPage Mul Hard) (s "multiplication" </> s "hard")
        , map (ProblemPage Mul Impossible) (s "multiplication" </> s "impossible")
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

            ProblemPage problemType difficulty ->
                "/"
                    ++ (case problemType of
                            AddSub ->
                                "addition"

                            Mul ->
                                "multiplication"
                       )
                    ++ "/"
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
