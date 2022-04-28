module Navigation exposing (pushRoute, toRoute)

import Browser.Navigation exposing (Key, pushUrl)
import Types exposing (..)
import Url exposing (Url)
import Url.Parser exposing ((</>), (<?>), Parser, map, oneOf, parse, s, top)
import Url.Parser.Query as Query


route : Parser (Route -> a) a
route =
    oneOf
        [ map Home top
        , map About (s "about")
        , map Authorize (s "authorize" <?> Query.string "access_token")
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
        , map (ProblemPage Sqrt Trivial) (s "square-root" </> s "trivial")
        , map (ProblemPage Sqrt Easy) (s "square-root" </> s "easy")
        , map (ProblemPage Sqrt Medium) (s "square-root" </> s "medium")
        , map (ProblemPage Sqrt Hard) (s "square-root" </> s "hard")
        , map (ProblemPage Sqrt Impossible) (s "square-root" </> s "impossible")
        , map (ProblemPage Exponent Trivial) (s "exponent" </> s "trivial")
        , map (ProblemPage Exponent Easy) (s "exponent" </> s "easy")
        , map (ProblemPage Exponent Medium) (s "exponent" </> s "medium")
        , map (ProblemPage Exponent Hard) (s "exponent" </> s "hard")
        , map (ProblemPage Exponent Impossible) (s "exponent" </> s "impossible")
        ]


toRoute : Url -> Route
toRoute url =
    let
        -- Yup, Auth0 puts queries in a fragment, so we need to work around it.
        url_ =
            url
                |> Url.toString
                |> String.replace "#" "?"
                |> Url.fromString
                |> Maybe.withDefault url
    in
    parse route url_
        |> Maybe.withDefault NotFound


pushRoute : Key -> Route -> Cmd msg
pushRoute key r =
    pushUrl key <|
        case r of
            Home ->
                "/"

            About ->
                "about"

            -- Should only be pushed by Auth0
            Authorize _ ->
                "/"

            ProblemPage problemType difficulty ->
                "/"
                    ++ (case problemType of
                            AddSub ->
                                "addition"

                            Mul ->
                                "multiplication"

                            Sqrt ->
                                "square-root"

                            Exponent ->
                                "exponent"
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
