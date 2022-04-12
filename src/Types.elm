module Types exposing (..)

import Browser
import Browser.Navigation exposing (Key)
import Lamdera exposing (ClientId, SessionId)
import Navigation exposing (Route)
import Time
import Url exposing (Url)


type alias BackendModel =
    { progress :
        { addSub : Maybe Difficulty
        }
    }


type alias FrontendModel =
    { problem : Problem
    , solvedProblems : Int
    , clientId : String
    , navigation :
        { url : Url
        , key : Key
        }
    }


type FrontendMsg
    = ProblemSolved
    | Tick Time.Posix
    | FrontendNoop
    | PushRoute Route
    | UrlChanged Url


type ToBackend
    = GetNewProblem


type BackendMsg
    = ClientConnected SessionId ClientId
    | SendProblem ClientId Problem


type ToFrontend
    = SetProblem Problem


type alias FrontendApp =
    { init : Url -> Key -> ( FrontendModel, Cmd FrontendMsg )
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
    , remainingTime : Float
    }



--type ProblemType
--    = AddSub


type Difficulty
    = Trivial
    | Easy
    | Medium
    | Hard
    | Impossible
