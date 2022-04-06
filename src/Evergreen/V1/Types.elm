module Evergreen.V1.Types exposing (..)

import Lamdera


type alias FrontendModel =
    { counter : Int
    , clientId : String
    }


type alias BackendModel =
    { counter : Int
    }


type FrontendMsg
    = Increment
    | FrontendNoop


type ToBackend
    = CounterIncremented


type BackendMsg
    = ClientConnected Lamdera.SessionId Lamdera.ClientId


type ToFrontend
    = CounterNewValue Int String
