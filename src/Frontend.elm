module Frontend exposing (..)

import Css exposing (..)
import Html.Styled exposing (Attribute, Html, button, div, text, toUnstyled)
import Html.Styled.Attributes exposing (css)
import Html.Styled.Events exposing (..)
import Lamdera exposing (sendToBackend)
import Time
import Types exposing (..)


type alias Model =
    FrontendModel


app : FrontendApp
app =
    Lamdera.frontend
        { init = \_ _ -> init
        , update = update
        , updateFromBackend = updateFromBackend
        , view =
            \model ->
                { title = "Mental Math Primer"
                , body = [ view model |> toUnstyled ]
                }
        , subscriptions = subscriptions
        , onUrlChange = \_ -> FrontendNoop
        , onUrlRequest = \_ -> FrontendNoop
        }


init : ( Model, Cmd FrontendMsg )
init =
    ( { problem =
            { statement = ""
            , choices = []
            , correct = 0
            , remainingTime = 10.0
            }
      , clientId = ""
      }
    , Cmd.none
    )


update : FrontendMsg -> Model -> ( Model, Cmd FrontendMsg )
update msg model =
    case msg of
        ProblemSolved ->
            ( model, sendToBackend GetNewProblem )

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
              }
            , if problem.remainingTime == 0 then
                sendToBackend GetNewProblem

              else
                Cmd.none
            )

        FrontendNoop ->
            ( model, Cmd.none )


updateFromBackend : ToFrontend -> Model -> ( Model, Cmd FrontendMsg )
updateFromBackend msg model =
    case msg of
        SetProblem problem ->
            ( { model | problem = problem }, Cmd.none )


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


problemBox : Problem -> Html FrontendMsg
problemBox { statement, choices, correct, remainingTime } =
    vdiv []
        [ vdiv [] [ statementText statement ]
        , timerText remainingTime
        , hdiv [] <|
            List.indexedMap
                (\i choice -> choiceButton (i == correct) choice)
                choices
        ]


view : Model -> Html FrontendMsg
view model =
    vdiv []
        [ Html.Styled.node "style" [] [ text bodyCss ]
        , problemBox model.problem
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
