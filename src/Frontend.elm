module Frontend exposing (..)

import Auth
import Browser
import Browser.Navigation exposing (Key, load)
import Config exposing (Env(..))
import Css exposing (..)
import Html.Styled exposing (Attribute, Html, button, div, h1, h2, li, ol, p, span, text, toUnstyled, ul)
import Html.Styled.Attributes exposing (css)
import Html.Styled.Events exposing (..)
import Lamdera exposing (sendToBackend)
import Navigation exposing (pushRoute, toRoute)
import Problem exposing (compareDifficulty, emptyProblem, emptyProgress)
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
    ( { problem = emptyProblem
      , solvedProblems = 0
      , clientId = ""
      , progress = emptyProgress
      , loggedIn = False
      , leaderboard = []
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
                [ sendToBackend (Login (access_token |> Maybe.withDefault ""))
                , pushRoute key Home
                ]

        _ ->
            Cmd.none
    )


update : FrontendMsg -> Model -> ( Model, Cmd FrontendMsg )
update msg model =
    case msg of
        Correct ->
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

        Incorrect ->
            ( { model | solvedProblems = 0 }
            , Cmd.batch
                [ pushRoute model.navigation.key Home
                , sendToBackend <|
                    PartialCompletion (getDifficulty model) model.solvedProblems
                ]
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
                Cmd.batch
                    [ pushRoute model.navigation.key Home
                    , sendToBackend <|
                        PartialCompletion (getDifficulty model) model.solvedProblems
                    ]

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

        StartLogout ->
            ( model, sendToBackend Logout )

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

        SetLeaderboard leaderboard ->
            ( { model | leaderboard = leaderboard }, Cmd.none )


applyProblemSpecs : Model -> (ProblemType -> Difficulty -> ToBackend) -> ToBackend
applyProblemSpecs model toBackend =
    case toRoute model.navigation.url of
        ProblemPage problemType difficulty ->
            toBackend problemType difficulty

        _ ->
            toBackend AddSub Trivial


getDifficulty : Model -> Difficulty
getDifficulty model =
    case toRoute model.navigation.url of
        ProblemPage _ difficulty ->
            difficulty

        _ ->
            Trivial


flexedDiv :
    Int
    -> { compatible | value : String, flexDirection : Compatible }
    -> List Style
    -> List (Html FrontendMsg)
    -> Html FrontendMsg
flexedDiv size direction style elements =
    div
        [ css
            ([ displayFlex
             , flex (int size)
             , flexDirection direction
             , alignItems center
             , justifyContent center
             ]
                ++ style
            )
        ]
        elements


vdiv : List Style -> List (Html FrontendMsg) -> Html FrontendMsg
vdiv =
    flexedDiv 1 column


hdiv : List Style -> List (Html FrontendMsg) -> Html FrontendMsg
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
            , fontSize (em 1)
            , padding (em 1)
            , margin (em 1)
            ]
            :: attributes
        )
        elements


choiceButton : Bool -> String -> Html FrontendMsg
choiceButton isCorrect choice =
    themedButton
        [ onClick
            (if isCorrect then
                Correct

             else
                Incorrect
            )
        , css
            [ fontSize (em 2)
            , padding (em 0.5)
            , if Config.mode == Development && isCorrect then
                border3 (px 2) solid theme.green

              else
                border3 (px 1) solid theme.primary
            ]
        ]
        [ text choice ]


problemBox : Problem -> Int -> Html FrontendMsg
problemBox { statement, choices, correct, remainingTime } solvedProblems =
    vdiv []
        [ vdiv [ flex (int 2) ] [ statementText statement ]
        , vdiv [] [ solvedDots solvedProblems ]
        , timerText remainingTime
        , hdiv [ flex (int 2) ] <|
            List.indexedMap
                (\i choice -> choiceButton (i == correct) choice)
                choices
        ]


menuView : Model -> Html FrontendMsg
menuView model =
    let
        problemSet : ProblemType -> String -> Html FrontendMsg
        problemSet problemType title =
            let
                accessor =
                    case problemType of
                        AddSub ->
                            .addSub

                        Mul ->
                            .mul

                        Sqrt ->
                            .sqrt

                        Exponent ->
                            .exponent

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
                        [ css <| width (em 7) :: difficultyBorder difficulty
                        , onClick (PushRoute <| ProblemPage problemType difficulty)
                        ]
            in
            hdiv []
                [ div [ css [ fontSize (em 3), width (em 1.5), textAlign center ] ] [ text title ]
                , difficultyButton Trivial [ text "Trivial" ]
                , difficultyButton Easy [ text "Easy" ]
                , difficultyButton Medium [ text "Medium" ]
                , difficultyButton Hard [ text "Hard" ]
                , difficultyButton Impossible [ text "Impossible" ]
                ]

        leaderboardButton =
            themedButton [ onClick (PushRoute Leaderboard) ] [ text "Leaderboard" ]

        aboutButton =
            themedButton [ onClick (PushRoute About) ] [ text "What is this?" ]

        loginButton =
            if model.loggedIn then
                themedButton [ onClick StartLogout ] [ text "Sign out" ]

            else
                themedButton [ onClick (Load Auth.authorizeUrl) ] [ text "Sign in with Google" ]

        scoreText =
            div
                [ css
                    [ margin (em 1)
                    , fontSize (em 2.5)
                    , textShadow4 (px 0) (px 0) (px 10) theme.accent
                    , fontFamily monospace
                    ]
                ]
                [ text "Score: "
                , span
                    [ css [] ]
                    [ text <| String.fromInt model.progress.score ]
                ]
    in
    vdiv []
        [ hdiv [ fontSize (em 3) ] [ text "Mental Math Primer" ]
        , problemSet AddSub "+-"
        , problemSet Mul "*"
        , problemSet Sqrt "√x"
        , problemSet Exponent "x²"
        , hdiv []
            [ scoreText
            , leaderboardButton
            , aboutButton
            , loginButton
            ]
        ]


problemView : Model -> Html FrontendMsg
problemView model =
    problemBox model.problem model.solvedProblems


aboutView : Html FrontendMsg
aboutView =
    let
        t element string =
            element [] [ text string ]
    in
    vdiv [ alignItems flexStart, maxWidth (em 30) ]
        [ t h1 "What is Mental Math Primer?"
        , t p """
              Simply put: Mental Math Primer is a tool that can be used to
              improve your ability to perform mental math. It is geared towards
              students practicing high school level math, but may be used by
              anyone looking to improve their math skills.
              """
        , t p """
              So why would you want to want to become better at something so
              seemingly useless? There might be a few reasons: 
              """
        , ul []
            [ t li "You are studying for college entrance exams"
            , t li "You make mistakes doing simple calculations"
            , t li "You are lazy like me and want to spend less time doing math"
            ]
        , t p """
              If you are here for any of the above reasons, let me explain how
              this simple web app can help you. First, let me ask you this: is
              it possible to be good at something without first mastering the
              basics of said something? No matter what you answer, fact is that
              being able to perform quick and accurate calculations is an
              advantage when studying mathematics. Mental Math Primer's main
              goal is to make it fun to become faster and more accurate doing
              "simple" calculations, through gamification.
              """
        , t h2 "Features"
        , ul []
            [ t li "Different types of problems"
            , t li "Several difficulty levels"
            , t li "Synced progress using a Google account"
            ]
        , t p """
              // Erik Mattfolk
              """
        ]


leaderboardView : Model -> Html FrontendMsg
leaderboardView model =
    vdiv []
        [ ol []
            (model.leaderboard
                |> List.map (\v -> li [] [ text (String.fromInt v) ])
            )
        ]


view : Model -> Html FrontendMsg
view model =
    vdiv
        [ backgroundColor theme.background
        , color theme.primary
        ]
        [ Html.Styled.node "style" [] [ text bodyCss ]
        , case toRoute model.navigation.url of
            Home ->
                menuView model

            About ->
                aboutView

            Leaderboard ->
                leaderboardView model

            Authorize _ ->
                menuView model

            ProblemPage _ _ ->
                problemView model

            NotFound ->
                vdiv [] [ text "404: Page not found!" ]
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


subscriptions : Model -> Sub FrontendMsg
subscriptions model =
    case toRoute model.navigation.url of
        ProblemPage _ _ ->
            Time.every 100 Tick

        _ ->
            Sub.batch []
