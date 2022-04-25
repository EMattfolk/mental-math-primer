module Backend exposing (app, init)

import Config
import Dict
import Http
import Json.Decode exposing (field, string)
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
    ( { progress = Dict.empty
      , sessionToProgressId = Dict.empty
      }
    , Cmd.none
    )


update : BackendMsg -> Model -> ( Model, Cmd BackendMsg )
update msg model =
    case msg of
        ClientConnected sessionId clientId ->
            ( model
            , Cmd.batch
                [ sendToFrontend clientId <|
                    SetProgress (getProgress sessionId model)
                , sendToFrontend clientId <|
                    SetLoggedIn (model.sessionToProgressId |> Dict.member sessionId)
                ]
            )

        SendProblem clientId problem ->
            ( model
            , sendToFrontend clientId <|
                SetProblem problem
            )

        LoggedIn sessionId clientId res ->
            let
                newModel =
                    case res of
                        Ok id ->
                            { model
                                | sessionToProgressId =
                                    model.sessionToProgressId
                                        |> Dict.insert sessionId id

                                -- TODO: Merge progress here
                            }

                        Err _ ->
                            model
            in
            ( newModel
            , Cmd.batch
                [ sendToFrontend clientId <|
                    SetProgress (getProgress sessionId newModel)
                , sendToFrontend clientId <| SetLoggedIn True
                ]
            )


updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
updateFromFrontend sessionId clientId msg model =
    case msg of
        GetNewProblem problemType difficulty ->
            ( model
            , Random.generate (SendProblem clientId) (randomProblem problemType difficulty)
            )

        LogIn access_token ->
            ( model
            , Http.request
                { method = "GET"
                , url = Config.auth0Url ++ "/userinfo"
                , headers =
                    [ Http.header "Authorization" ("Bearer " ++ access_token) ]
                , body = Http.emptyBody
                , timeout = Nothing
                , tracker = Nothing
                , expect = Http.expectJson (LoggedIn sessionId clientId) (field "sub" string)
                }
            )

        LogOut ->
            let
                newModel =
                    { model
                        | sessionToProgressId =
                            model.sessionToProgressId
                                |> Dict.remove sessionId
                    }
            in
            ( newModel
            , Cmd.batch
                [ sendToFrontend clientId <|
                    SetProgress (getProgress sessionId newModel)
                , sendToFrontend clientId <|
                    SetLoggedIn False
                ]
            )

        SaveProgress problemType difficulty ->
            let
                id =
                    model.sessionToProgressId
                        |> Dict.get sessionId
                        |> Maybe.withDefault sessionId

                newModel =
                    { model
                        | progress =
                            model.progress
                                |> Dict.update id
                                    (\maybeProgress ->
                                        let
                                            progress =
                                                maybeProgress |> Maybe.withDefault emptyProgress

                                            mergeIfCorrectProblem savedType savedProgress =
                                                let
                                                    merged =
                                                        savedProgress
                                                            |> Maybe.map
                                                                (\saved ->
                                                                    if compareDifficulty difficulty saved == GT then
                                                                        difficulty

                                                                    else
                                                                        saved
                                                                )
                                                            |> Maybe.withDefault difficulty
                                                            |> Just
                                                in
                                                if savedType == problemType then
                                                    merged

                                                else
                                                    savedProgress
                                        in
                                        Just
                                            { addSub =
                                                progress
                                                    |> .addSub
                                                    |> mergeIfCorrectProblem AddSub
                                            , mul =
                                                progress
                                                    |> .mul
                                                    |> mergeIfCorrectProblem Mul
                                            }
                                    )
                    }
            in
            ( newModel
            , sendToFrontend clientId <|
                SetProgress (getProgress sessionId newModel)
            )


getProgress : SessionId -> Model -> Progress
getProgress sessionId model =
    model.progress
        |> Dict.get
            (model.sessionToProgressId
                |> Dict.get sessionId
                |> Maybe.withDefault sessionId
            )
        |> Maybe.withDefault emptyProgress


subscriptions : Model -> Sub BackendMsg
subscriptions _ =
    Sub.batch
        [ Lamdera.onConnect ClientConnected
        ]
