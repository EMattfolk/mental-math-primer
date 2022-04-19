module Evergreen.V6.Types exposing (..)

import Browser.Navigation
import Dict
import Lamdera
import Time
import Url


type alias Problem =
    { statement : String
    , choices : List String
    , correct : Int
    , remainingTime : Float
    }


type Difficulty
    = Trivial
    | Easy
    | Medium
    | Hard
    | Impossible


type alias Progress =
    { addSub : Maybe Difficulty
    , mul : Maybe Difficulty
    }


type alias FrontendModel =
    { problem : Problem
    , solvedProblems : Int
    , clientId : String
    , progress : Progress
    , navigation :
        { url : Url.Url
        , key : Browser.Navigation.Key
        }
    }


type alias BackendModel =
    Dict.Dict Lamdera.SessionId Progress


type ProblemType
    = AddSub
    | Mul


type Route
    = Home
    | ProblemPage ProblemType Difficulty
    | NotFound


type FrontendMsg
    = ProblemSolved
    | Tick Time.Posix
    | FrontendNoop
    | PushRoute Route
    | UrlChanged Url.Url


type ToBackend
    = GetNewProblem ProblemType Difficulty
    | SaveProgress ProblemType Difficulty


type BackendMsg
    = ClientConnected Lamdera.SessionId Lamdera.ClientId
    | SendProblem Lamdera.ClientId Problem


type ToFrontend
    = SetProblem Problem
    | SetProgress Progress
