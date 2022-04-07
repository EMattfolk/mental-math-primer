module Frontend exposing (..)

import Css exposing (..)
import Html.Events exposing (..)
import Html.Styled exposing (button, div, text, toUnstyled)
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
    ( { counter = 0, clientId = "" }, Cmd.none )


update : FrontendMsg -> Model -> ( Model, Cmd FrontendMsg )
update msg model =
    case msg of
        Increment ->
            ( { model | counter = model.counter + 1 }, sendToBackend CounterIncremented )

        FrontendNoop ->
            ( model, Cmd.none )


updateFromBackend : ToFrontend -> Model -> ( Model, Cmd FrontendMsg )
updateFromBackend msg model =
    case msg of
        CounterNewValue newCounter clientId ->
            ( { model | counter = newCounter, clientId = clientId }, Cmd.none )


flexedDiv size direction attributes elements =
    div
        ([ css
            [ displayFlex
            , flex (int size)
            , flexGrow (int 1)
            , flexDirection direction
            , alignItems center
            , justifyContent center
            ]
         ]
            ++ attributes
        )
        elements


vdiv =
    flexedDiv 1 column


hdiv =
    flexedDiv 1 row


problemBox : String -> List String -> Html.Styled.Html FrontendMsg
problemBox problemText options =
    vdiv [] <|
        [ vdiv [] [ text problemText ]
        , hdiv [] <| List.map (\option -> button [] [ text option ]) options
        ]


view : Model -> Html.Styled.Html FrontendMsg
view _ =
    vdiv []
        [ Html.Styled.node "style" [] [ text bodyCss ]
        , problemBox "1 + 1" [ "1", "2", "3" ]
        ]


bodyCss =
    """
    body {
        display: flex;
        flex-direction: column;
        height: 100vh;
    }
    """
