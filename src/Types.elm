module Types exposing (..)

import Browser
import Browser.Navigation exposing (Key)
import Dict exposing (Dict)
import Http
import Lamdera exposing (ClientId, SessionId)
import Time
import Url exposing (Url)


type alias BackendModel =
    { progress : Dict String Progress
    , sessionToProgressId : Dict SessionId String
    }


type alias FrontendModel =
    { problem : Problem
    , solvedProblems : Int
    , clientId : String
    , progress : Progress
    , loggedIn : Bool
    , leaderboard : List Int
    , navigation :
        { url : Url
        , key : Key
        }
    }


type FrontendMsg
    = Correct
    | Incorrect
    | Tick Time.Posix
    | PushRoute Route
    | Load String
    | UrlChanged Url
    | StartLogout
    | FrontendNoop


type ToBackend
    = GetNewProblem ProblemType Difficulty
    | SaveProgress ProblemType Difficulty
    | PartialCompletion Difficulty Int
    | Login String
    | Logout


type BackendMsg
    = ClientConnected SessionId ClientId
    | SendProblem ClientId Problem
    | LoggedIn SessionId ClientId (Result Http.Error String)


type ToFrontend
    = SetProblem Problem
    | SetProgress Progress
    | SetLoggedIn Bool
    | SetLeaderboard (List Int)


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


type alias Progress =
    { addSub : Maybe Difficulty
    , mul : Maybe Difficulty
    , sqrt : Maybe Difficulty
    , exponent : Maybe Difficulty
    , score : Int
    }


type ProblemType
    = AddSub
    | Mul
    | Sqrt
    | Exponent


type Difficulty
    = Trivial
    | Easy
    | Medium
    | Hard
    | Impossible


type Route
    = Home
    | About
    | Leaderboard
    | Authorize (Maybe String)
    | ProblemPage ProblemType Difficulty
    | NotFound
