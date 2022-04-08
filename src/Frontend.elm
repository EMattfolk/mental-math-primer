module Frontend exposing (..)

import Css exposing (..)
import Html.Events exposing (..)
import Html.Styled exposing (Attribute, Html, button, div, text, toUnstyled)
import Html.Styled.Attributes exposing (css)
import Lamdera exposing (sendToBackend)
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
        , subscriptions = \_ -> Sub.none
        , onUrlChange = \_ -> FrontendNoop
        , onUrlRequest = \_ -> FrontendNoop
        }


init : ( Model, Cmd FrontendMsg )
init =
    ( { problem = { statement = "", choices = [] }, clientId = "" }, Cmd.none )


update : FrontendMsg -> Model -> ( Model, Cmd FrontendMsg )
update msg model =
    case msg of
        Increment ->
            ( model, sendToBackend CounterIncremented )

        FrontendNoop ->
            ( model, Cmd.none )


updateFromBackend : ToFrontend -> Model -> ( Model, Cmd FrontendMsg )
updateFromBackend msg model =
    case msg of
        CounterNewValue _ clientId ->
            ( { model | clientId = clientId }, Cmd.none )

        SetProblem problem ->
            ( { model | problem = problem }, Cmd.none )


flexedDiv :
    Int
    -> { compatible | value : String, flexDirection : Compatible }
    -> List (Attribute msg)
    -> List (Html msg)
    -> Html msg
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


vdiv : List (Attribute msg) -> List (Html msg) -> Html msg
vdiv =
    flexedDiv 1 column


hdiv : List (Attribute msg) -> List (Html msg) -> Html msg
hdiv =
    flexedDiv 1 row


problemBox : Problem -> Html FrontendMsg
problemBox { statement, choices } =
    vdiv [] <|
        [ vdiv [] [ text statement ]
        , hdiv [] <| List.map (\option -> button [] [ text option ]) choices
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
