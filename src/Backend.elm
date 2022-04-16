module Backend exposing (app, init)

import Lamdera exposing (ClientId, SessionId, sendToFrontend)
import Problem exposing (compareDifficulty, randomProblem)
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
    ( { progress =
            { addSub = Nothing
            }
      }
    , Cmd.none
    )


update : BackendMsg -> Model -> ( Model, Cmd BackendMsg )
update msg model =
    case msg of
        ClientConnected _ clientId ->
            -- FIXME: This should probably do something
            ( model
            , sendToFrontend clientId <| SetProgress model.progress
            )

        SendProblem clientId problem ->
            ( model
            , sendToFrontend clientId <|
                SetProblem problem
            )


updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
updateFromFrontend _ clientId msg model =
    case msg of
        GetNewProblem difficulty ->
            ( model
            , Random.generate (SendProblem clientId) (randomProblem difficulty)
            )

        SaveProgress difficulty ->
            let
                newModel =
                    { model
                        | progress =
                            { addSub =
                                case ( difficulty, model.progress.addSub ) of
                                    ( _, Nothing ) ->
                                        Just difficulty

                                    ( _, Just saved ) ->
                                        if compareDifficulty difficulty saved == GT then
                                            Just difficulty

                                        else
                                            Just saved
                            }
                    }
            in
            ( newModel
            , sendToFrontend clientId <| SetProgress newModel.progress
            )


subscriptions : Model -> Sub BackendMsg
subscriptions _ =
    Sub.batch
        [ Lamdera.onConnect ClientConnected
        ]
