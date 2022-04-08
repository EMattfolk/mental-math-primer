module Types exposing (..)

import Browser
import Browser.Navigation
import Lamdera exposing (ClientId, SessionId)
import Url exposing (Url)


type alias BackendModel =
    { counter : Int
    }


type alias FrontendModel =
    { problem : Problem
    , clientId : String
    }


type FrontendMsg
    = ProblemSolved
    | FrontendNoop


type ToBackend
    = GetNewProblem


type BackendMsg
    = ClientConnected SessionId ClientId
    | SendProblem ClientId Problem


type ToFrontend
    = CounterNewValue Int String
    | SetProblem Problem


type alias FrontendApp =
    { init : Url -> Browser.Navigation.Key -> ( FrontendModel, Cmd FrontendMsg )
    , view : FrontendModel -> Browser.Document FrontendMsg
    , update : FrontendMsg -> FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
    , updateFromBackend : ToFrontend -> FrontendModel -> ( FrontendModel, Cmd FrontendMsg )
    , subscriptions : FrontendModel -> Sub FrontendMsg
    , onUrlRequest : Browser.UrlRequest -> FrontendMsg
    , onUrlChange : Url.Url -> FrontendMsg
    }


type alias BackendApp =
    { init : ( BackendModel, Cmd BackendMsg )
    , update : BackendMsg -> BackendModel -> ( BackendModel, Cmd BackendMsg )
    , updateFromFrontend : SessionId -> ClientId -> ToBackend -> BackendModel -> ( BackendModel, Cmd BackendMsg )
    , subscriptions : BackendModel -> Sub BackendMsg
    }


type alias Problem =
    { statement : String
    , choices : List String
    , correct : Int
    }
