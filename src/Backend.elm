module Backend exposing (app, init)

import Lamdera exposing (ClientId, SessionId, broadcast, sendToFrontend)
import Random exposing (Generator)
import Types exposing (..)


type alias Model =
    BackendModel


app : BackendApp
app =
    Lamdera.backend
        { init = init
        , update = update
        , updateFromFrontend = updateFromFrontend
        , subscriptions = subscriptions
        }


init : ( Model, Cmd BackendMsg )
init =
    ( { counter = 0 }, Cmd.none )


randomProblem : Generator Problem
randomProblem =
    let
        t1 =
            Random.int 1 5

        t2 =
            Random.int 1 5

        statement =
            Random.map2 (\a b -> String.fromInt a ++ " + " ++ String.fromInt b) t1 t2

        choices =
            Random.map2 (\a b -> List.map String.fromInt [ a + b - 2, a + b, a + b + 2 ]) t1 t2
    in
    Random.map2 Problem statement choices


update : BackendMsg -> Model -> ( Model, Cmd BackendMsg )
update msg model =
    case msg of
        ClientConnected _ clientId ->
            ( model
            , Random.generate (SendProblem clientId) randomProblem
            )

        SendProblem clientId problem ->
            ( model
            , sendToFrontend clientId <|
                SetProblem problem
            )


updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
updateFromFrontend _ clientId msg model =
    case msg of
        CounterIncremented ->
            let
                newCounter =
                    model.counter + 1
            in
            ( { model | counter = newCounter }
            , broadcast (CounterNewValue newCounter clientId)
            )


subscriptions : Model -> Sub BackendMsg
subscriptions _ =
    Sub.batch
        [ Lamdera.onConnect ClientConnected
        ]
