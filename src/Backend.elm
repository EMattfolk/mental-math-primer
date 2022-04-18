module Backend exposing (app, init)

import Dict
import Lamdera exposing (ClientId, SessionId, sendToFrontend)
import Problem exposing (compareDifficulty, emptyProgress, randomProblem)
import Random
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
    ( Dict.empty
    , Cmd.none
    )


update : BackendMsg -> Model -> ( Model, Cmd BackendMsg )
update msg model =
    case msg of
        ClientConnected sessionId clientId ->
            ( model
            , sendToFrontend clientId <|
                SetProgress
                    (model
                        |> Dict.get sessionId
                        |> Maybe.withDefault emptyProgress
                    )
            )

        SendProblem clientId problem ->
            ( model
            , sendToFrontend clientId <|
                SetProblem problem
            )


updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
updateFromFrontend sessionId clientId msg model =
    case msg of
        GetNewProblem problemType difficulty ->
            ( model
            , Random.generate (SendProblem clientId) (randomProblem problemType difficulty)
            )

        SaveProgress _ difficulty ->
            let
                newModel =
                    model
                        |> Dict.update sessionId
                            (\maybeProgress ->
                                let
                                    progress =
                                        maybeProgress |> Maybe.withDefault emptyProgress
                                in
                                Just
                                    { addSub =
                                        progress
                                            |> .addSub
                                            |> Maybe.map
                                                (\saved ->
                                                    if compareDifficulty difficulty saved == GT then
                                                        difficulty

                                                    else
                                                        saved
                                                )
                                            |> Maybe.withDefault difficulty
                                            |> Just
                                    }
                            )
            in
            ( newModel
            , sendToFrontend clientId <|
                SetProgress
                    (newModel
                        |> Dict.get sessionId
                        |> Maybe.withDefault emptyProgress
                    )
            )


subscriptions : Model -> Sub BackendMsg
subscriptions _ =
    Sub.batch
        [ Lamdera.onConnect ClientConnected
        ]
