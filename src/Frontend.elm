module Frontend exposing (..)

import Browser.Navigation exposing (Key, back)
import Css exposing (..)
import Html.Styled exposing (Attribute, Html, button, div, text, toUnstyled)
import Html.Styled.Attributes exposing (css)
import Html.Styled.Events exposing (..)
import Lamdera exposing (sendToBackend)
import Navigation exposing (pushRoute, toRoute)
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
        , onUrlRequest = \_ -> FrontendNoop
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
      , navigation =
            { url = url
            , key = key
            }
      }
    , case toRoute url of
        ProblemPage difficulty ->
            sendToBackend (GetNewProblem difficulty)

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
                back model.navigation.key 1

              else
                sendToBackend <| GetNewProblem (getDifficulty model)
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
                sendToBackend <| GetNewProblem (getDifficulty model)

              else
                Cmd.none
            )

        PushRoute route ->
            ( model
            , Cmd.batch
                [ pushRoute model.navigation.key route
                , sendToBackend <| GetNewProblem (getDifficulty model)
                ]
            )

        UrlChanged url ->
            let
                { navigation } =
                    model
            in
            ( { model
                | navigation =
                    { navigation
                        | url = url
                    }
                , solvedProblems = 0
              }
            , sendToBackend <| GetNewProblem (getDifficulty model)
            )

        FrontendNoop ->
            ( model, Cmd.none )


updateFromBackend : ToFrontend -> Model -> ( Model, Cmd FrontendMsg )
updateFromBackend msg model =
    case msg of
        SetProblem problem ->
            ( { model | problem = problem }, Cmd.none )


getDifficulty : Model -> Difficulty
getDifficulty model =
    case toRoute model.navigation.url of
        ProblemPage difficulty ->
            difficulty

        _ ->
            Trivial


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


choiceButton : Bool -> String -> Html FrontendMsg
choiceButton isCorrect choice =
    button
        [ onClick
            (if isCorrect then
                ProblemSolved

             else
                FrontendNoop
            )
        , css
            [ borderRadius (em 10)
            , width (em 2)
            , height (em 2)
            , fontSize (em 2)
            , margin (em 1)
            , boxShadow4 (px 3) (px 3) (px 5) (rgb 211 211 211)
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
menuView _ =
    let
        listItem : (Difficulty -> Route) -> String -> Html FrontendMsg
        listItem route title =
            hdiv
                [ css
                    [ fontSize (em 2)
                    ]
                ]
                [ text title
                , button [ onClick (PushRoute <| route Trivial) ] [ text "Trivial" ]
                , button [ onClick (PushRoute <| route Easy) ] [ text "Easy" ]
                , button [ onClick (PushRoute <| route Medium) ] [ text "Medium" ]
                , button [ onClick (PushRoute <| route Hard) ] [ text "Hard" ]
                , button [ onClick (PushRoute <| route Impossible) ] [ text "Impossible" ]
                ]
    in
    vdiv []
        [ hdiv
            [ css
                [ fontSize (em 3)
                ]
            ]
            [ text "Mental Math Primer" ]
        , listItem ProblemPage "+-"
        ]


problemView : Model -> Html FrontendMsg
problemView model =
    problemBox model.problem model.solvedProblems


view : Model -> Html FrontendMsg
view model =
    vdiv []
        [ Html.Styled.node "style" [] [ text bodyCss ]
        , case toRoute model.navigation.url of
            Home ->
                menuView model

            ProblemPage _ ->
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
    }
    """


subscriptions : model -> Sub FrontendMsg
subscriptions _ =
    Sub.batch
        [ Time.every 100 Tick
        ]
