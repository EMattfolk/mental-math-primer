module Evergreen.V4.Types exposing (..)

import Browser.Navigation
import Lamdera
import Time
import Url


type alias Problem =
    { statement : String
    , choices : List String
    , correct : Int
    , remainingTime : Float
    }


type alias FrontendModel =
    { problem : Problem
    , solvedProblems : Int
    , clientId : String
    , navigation :
        { url : Url.Url
        , key : Browser.Navigation.Key
        }
    }


type Difficulty
    = Trivial
    | Easy
    | Medium
    | Hard
    | Impossible


type alias BackendModel =
    { progress :
        { addSub : Maybe Difficulty
        }
    }


type FrontendMsg
    = ProblemSolved
    | Tick Time.Posix
    | FrontendNoop
    | PushUrl String
    | UrlChanged Url.Url


type ToBackend
    = GetNewProblem


type BackendMsg
    = ClientConnected Lamdera.SessionId Lamdera.ClientId
    | SendProblem Lamdera.ClientId Problem
    | BackendNoop


type ToFrontend
    = SetProblem Problem
