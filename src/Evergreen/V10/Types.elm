module Evergreen.V10.Types exposing (..)

import Browser.Navigation
import Dict
import Http
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
    , sqrt : Maybe Difficulty
    , exponent : Maybe Difficulty
    }


type alias FrontendModel =
    { problem : Problem
    , solvedProblems : Int
    , clientId : String
    , progress : Progress
    , loggedIn : Bool
    , navigation :
        { url : Url.Url
        , key : Browser.Navigation.Key
        }
    }


type alias BackendModel =
    { progress : Dict.Dict String Progress
    , sessionToProgressId : Dict.Dict Lamdera.SessionId String
    }


type ProblemType
    = AddSub
    | Mul
    | Sqrt
    | Exponent


type Route
    = Home
    | Authorize (Maybe String)
    | ProblemPage ProblemType Difficulty
    | NotFound


type FrontendMsg
    = ProblemSolved
    | Tick Time.Posix
    | FrontendNoop
    | PushRoute Route
    | Load String
    | UrlChanged Url.Url
    | StartLogout


type ToBackend
    = GetNewProblem ProblemType Difficulty
    | SaveProgress ProblemType Difficulty
    | Login String
    | Logout


type BackendMsg
    = ClientConnected Lamdera.SessionId Lamdera.ClientId
    | SendProblem Lamdera.ClientId Problem
    | LoggedIn Lamdera.SessionId Lamdera.ClientId (Result Http.Error String)


type ToFrontend
    = SetProblem Problem
    | SetProgress Progress
    | SetLoggedIn Bool
