module Frontend exposing (..)

import Html exposing (div, text)
import Html.Events exposing (..)
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
                , body = [ view model ]
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


view : Model -> Html.Html FrontendMsg
view model =
    div [ onClick Increment ]
        [ text ("hello " ++ String.fromInt model.counter)
        ]
