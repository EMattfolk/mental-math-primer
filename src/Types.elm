module Types exposing (..)

import Lamdera exposing (ClientId, SessionId)


type alias BackendModel =
    { counter : Int
    }


type alias FrontendModel =
    { counter : Int
    , clientId : String
    }


type FrontendMsg
    = Increment
    | FrontendNoop


type ToBackend
    = CounterIncremented


type BackendMsg
    = ClientConnected SessionId ClientId


type ToFrontend
    = CounterNewValue Int String
