module Main exposing (..)

import Browser
import Html exposing (div, text)
import Html.Events exposing (..)


main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = \_ -> Sub.none
        , view = view
        }


type alias Model =
    Int


init : () -> ( Model, Cmd Msg )
init _ =
    ( 0, Cmd.none )


type Msg
    = Increment


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Increment ->
            ( model + 1, Cmd.none )


view : Model -> Html.Html Msg
view model =
    div [ onClick Increment ]
        [ text ("hello " ++ String.fromInt model)
        ]
