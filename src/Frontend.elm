module Frontend exposing (..)

import Auth0 exposing (Auth0Config, auth0AuthorizeURL)
import Browser
import Browser.Navigation exposing (Key, load)
import Config exposing (Env(..))
import Css exposing (..)
import Html.Styled exposing (Attribute, Html, a, button, div, text, toUnstyled)
import Html.Styled.Attributes exposing (css, href)
import Html.Styled.Events exposing (..)
import Lamdera exposing (sendToBackend)
import Navigation exposing (pushRoute, toRoute)
import Problem exposing (compareDifficulty, emptyProgress)
import Time
import Types exposing (..)
import Url


type alias Model =
    FrontendModel


app : FrontendApp
app =
    Lamdera.frontend
        { init = init
        , update = update
        , updateFromBackend = updateFromBackend
        , view =
            \model ->
                { title = "Mental Math Primer"
                , body = [ view model |> toUnstyled ]
                }
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest =
            \request ->
                case request of
                    Browser.External path ->
                        Load path

                    _ ->
                        FrontendNoop
        }


init : Url.Url -> Key -> ( Model, Cmd FrontendMsg )
init url key =
    ( { problem =
            { statement = ""
            , choices = []
            , correct = 0
            , remainingTime = 10.0
            }
      , solvedProblems = 0
      , clientId = ""
      , progress = emptyProgress
      , loggedIn = False
      , navigation =
            { url = url
            , key = key
            }
      }
    , case toRoute url of
        ProblemPage problemType difficulty ->
            sendToBackend (GetNewProblem problemType difficulty)

        Authorize access_token ->
            Cmd.batch
                [ sendToBackend (LogIn (access_token |> Maybe.withDefault ""))
                , pushRoute key Home
                ]

        _ ->
            Cmd.none
    )


update : FrontendMsg -> Model -> ( Model, Cmd FrontendMsg )
update msg model =
    case msg of
        ProblemSolved ->
            -- hack
            ( { model | solvedProblems = modBy 10 (model.solvedProblems + 1) }
            , if model.solvedProblems == 9 then
                Cmd.batch
                    [ pushRoute model.navigation.key Home
                    , SaveProgress
                        |> applyProblemSpecs model
                        |> sendToBackend
                    ]

              else
                GetNewProblem
                    |> applyProblemSpecs model
                    |> sendToBackend
            )

        Tick _ ->
            let
                { problem } =
                    model
            in
            ( { model
                | problem =
                    { problem
                        | remainingTime = max (problem.remainingTime - 0.1) 0.0
                    }
                , solvedProblems =
                    if problem.remainingTime == 0 then
                        0

                    else
                        model.solvedProblems
              }
            , if problem.remainingTime == 0 then
                GetNewProblem
                    |> applyProblemSpecs model
                    |> sendToBackend

              else
                Cmd.none
            )

        PushRoute route ->
            ( model, pushRoute model.navigation.key route )

        Load path ->
            ( model, load path )

        UrlChanged url ->
            let
                { navigation } =
                    model

                newModel =
                    { model
                        | navigation =
                            { navigation
                                | url = url
                            }
                        , solvedProblems = 0
                    }
            in
            ( newModel
            , GetNewProblem
                |> applyProblemSpecs newModel
                |> sendToBackend
            )

        StartLogOut ->
            ( model, sendToBackend LogOut )

        FrontendNoop ->
            ( model, Cmd.none )


updateFromBackend : ToFrontend -> Model -> ( Model, Cmd FrontendMsg )
updateFromBackend msg model =
    case msg of
        SetProblem problem ->
            ( { model | problem = problem }, Cmd.none )

        SetProgress progress ->
            ( { model | progress = progress }, Cmd.none )

        SetLoggedIn loggedIn ->
            ( { model | loggedIn = loggedIn }, Cmd.none )


applyProblemSpecs : Model -> (ProblemType -> Difficulty -> ToBackend) -> ToBackend
applyProblemSpecs model toBackend =
    case toRoute model.navigation.url of
        ProblemPage problemType difficulty ->
            toBackend problemType difficulty

        _ ->
            toBackend AddSub Trivial


flexedDiv :
    Int
    -> { compatible | value : String, flexDirection : Compatible }
    -> List (Attribute FrontendMsg)
    -> List (Html FrontendMsg)
    -> Html FrontendMsg
flexedDiv size direction attributes elements =
    div
        (css
            [ displayFlex
            , flex (int size)
            , flexDirection direction
            , alignItems center
            , justifyContent center
            ]
            :: attributes
        )
        elements


vdiv : List (Attribute FrontendMsg) -> List (Html FrontendMsg) -> Html FrontendMsg
vdiv =
    flexedDiv 1 column


hdiv : List (Attribute FrontendMsg) -> List (Html FrontendMsg) -> Html FrontendMsg
hdiv =
    flexedDiv 1 row


statementText : String -> Html FrontendMsg
statementText statement =
    div
        [ css
            [ fontSize (em 4)
            ]
        ]
        [ text statement
        ]


solvedDots : Int -> Html FrontendMsg
solvedDots solvedProblems =
    div
        [ css
            [ fontSize (em 2)
            ]
        ]
        [ text
            (String.repeat (min solvedProblems 10) "⚫"
                ++ String.repeat (10 - solvedProblems) "⚪"
            )
        ]


timerText : Float -> Html FrontendMsg
timerText remainingTime =
    div
        [ css
            [ fontSize (em 2)
            ]
        ]
        [ text <| (String.fromInt << floor) remainingTime
        ]


themedButton : List (Attribute FrontendMsg) -> List (Html FrontendMsg) -> Html FrontendMsg
themedButton attributes elements =
    button
        (css
            [ backgroundColor theme.accent
            , color theme.primary
            , border3 (px 1) solid theme.primary
            , boxShadow4 (px 0) (px 0) (px 10) theme.accent
            , borderRadius (em 10)
            , cursor pointer
            ]
            :: attributes
        )
        elements


choiceButton : Bool -> String -> Html FrontendMsg
choiceButton isCorrect choice =
    themedButton
        [ onClick
            (if isCorrect then
                ProblemSolved

             else
                FrontendNoop
            )
        , css
            [ fontSize (em 2)
            , margin (em 1)
            , padding (em 0.5)
            ]
        ]
        [ text choice ]


problemBox : Problem -> Int -> Html FrontendMsg
problemBox { statement, choices, correct, remainingTime } solvedProblems =
    vdiv []
        [ vdiv [ css [ flex (int 2) ] ] [ statementText statement ]
        , vdiv [] [ solvedDots solvedProblems ]
        , timerText remainingTime
        , hdiv [ css [ flex (int 2) ] ] <|
            List.indexedMap
                (\i choice -> choiceButton (i == correct) choice)
                choices
        ]


menuView : Model -> Html FrontendMsg
menuView model =
    let
        listItem : ProblemType -> String -> Html FrontendMsg
        listItem problemType title =
            let
                accessor =
                    case problemType of
                        AddSub ->
                            .addSub

                        Mul ->
                            .mul

                difficultyBorder difficulty =
                    case
                        model.progress
                            |> accessor
                            |> Maybe.map (\saved -> compareDifficulty difficulty saved /= GT)
                    of
                        Just True ->
                            [ border3 (px 2) solid theme.green ]

                        _ ->
                            [ border3 (px 1) solid theme.primary ]

                difficultyButton : Difficulty -> List (Html FrontendMsg) -> Html FrontendMsg
                difficultyButton difficulty =
                    themedButton
                        [ css
                            ([ fontSize (em 0.25) -- To parry (em 4) below
                             , width (em 7)
                             , margin (em 1)
                             , padding (em 1)
                             ]
                                ++ difficultyBorder difficulty
                            )
                        , onClick (PushRoute <| ProblemPage problemType difficulty)
                        ]
            in
            hdiv
                [ css
                    [ fontSize (em 4)
                    ]
                ]
                [ text title
                , difficultyButton Trivial [ text "Trivial" ]
                , difficultyButton Easy [ text "Easy" ]
                , difficultyButton Medium [ text "Medium" ]
                , difficultyButton Hard [ text "Hard" ]
                , difficultyButton Impossible [ text "Impossible" ]
                ]

        loginButton =
            if model.loggedIn then
                themedButton [ onClick StartLogOut ] [ text "Sign out" ]

            else
                themedButton [ onClick (Load authUrl) ] [ text "Sign in with Google" ]
    in
    vdiv []
        [ hdiv
            [ css
                [ fontSize (em 3)
                ]
            ]
            [ text "Mental Math Primer" ]
        , listItem AddSub "+-"
        , listItem Mul "*"
        , loginButton
        ]


problemView : Model -> Html FrontendMsg
problemView model =
    problemBox model.problem model.solvedProblems


view : Model -> Html FrontendMsg
view model =
    vdiv
        [ css
            [ backgroundColor theme.background
            , color theme.primary
            ]
        ]
        [ Html.Styled.node "style" [] [ text bodyCss ]
        , case toRoute model.navigation.url of
            Home ->
                menuView model

            Authorize _ ->
                menuView model

            ProblemPage _ _ ->
                problemView model

            NotFound ->
                text "404: Page not found!"
        ]


bodyCss : String
bodyCss =
    """
    body {
        display: flex;
        flex-direction: column;
        height: 100vh;
        margin: 0;
        padding: 0;
    }
    """


theme : { primary : Color, background : Color, accent : Color, green : Color, red : Color }
theme =
    { primary = rgb 253 232 233
    , background = rgb 31 34 50
    , accent = rgb 50 54 70
    , green = rgb 76 185 68
    , red = rgb 254 74 73
    }


authUrl : String
authUrl =
    auth0AuthorizeURL
        (Auth0Config Config.auth0Url "pJsQXQKLDptayHhSm3vt42jOJPYFx1xT")
        "token"
        (case Config.mode of
            Development ->
                "http://localhost:8000/authorize"

            Production ->
                "https://mental-math-primer.lamdera.app/authorize"
        )
        [ "openid", "name", "email" ]
        (Just "google-oauth2")


subscriptions : Model -> Sub FrontendMsg
subscriptions model =
    case toRoute model.navigation.url of
        ProblemPage _ _ ->
            Time.every 100 Tick

        _ ->
            Sub.batch []
