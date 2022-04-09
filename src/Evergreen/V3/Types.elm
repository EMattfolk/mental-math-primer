module Evergreen.V3.Types exposing (..)

import Lamdera


type alias Problem =
    { statement : String
    , choices : List String
    , correct : Int
    }


type alias FrontendModel =
    { problem : Problem
    , clientId : String
    }


type alias BackendModel =
    { counter : Int
    }


type FrontendMsg
    = ProblemSolved
    | FrontendNoop


type ToBackend
    = GetNewProblem


type BackendMsg
    = ClientConnected Lamdera.SessionId Lamdera.ClientId
    | SendProblem Lamdera.ClientId Problem


type ToFrontend
    = CounterNewValue Int String
    | SetProblem Problem
