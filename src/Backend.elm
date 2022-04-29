module Backend exposing (app, init)

import Auth
import Config
import Dict
import Http
import Json.Decode exposing (field, string)
import Lamdera exposing (ClientId, SessionId, sendToFrontend)
import Problem exposing (emptyProgress, mergeProgress, randomProblem)
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
                                , progress =
                                    model.progress
                                        |> Dict.update id
                                            (\maybeProgress ->
                                                let
                                                    currentProgress =
                                                        model.progress |> Dict.get sessionId
                                                in
                                                Just <|
                                                    mergeProgress
                                                        (Maybe.withDefault
                                                            emptyProgress
                                                            maybeProgress
                                                        )
                                                        (Maybe.withDefault
                                                            emptyProgress
                                                            currentProgress
                                                        )
                                            )
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

        Login access_token ->
            ( model
            , Http.request
                { method = "GET"
                , url = Auth.userinfoUrl
                , headers =
                    [ Http.header "Authorization" ("Bearer " ++ access_token) ]
                , body = Http.emptyBody
                , timeout = Nothing
                , tracker = Nothing
                , expect = Http.expectJson (LoggedIn sessionId clientId) (field "sub" string)
                }
            )

        Logout ->
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
                                                maybeProgress
                                                    |> Maybe.withDefault emptyProgress

                                            justIfProblem fieldType d =
                                                if fieldType == problemType then
                                                    Just d

                                                else
                                                    Nothing

                                            newProgress =
                                                { addSub =
                                                    difficulty
                                                        |> justIfProblem AddSub
                                                , mul =
                                                    difficulty
                                                        |> justIfProblem Mul
                                                , sqrt =
                                                    difficulty
                                                        |> justIfProblem Sqrt
                                                , exponent =
                                                    difficulty
                                                        |> justIfProblem Exponent
                                                }
                                        in
                                        Just <|
                                            mergeProgress progress newProgress
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
