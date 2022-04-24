module Config exposing (..)

import Env as LamderaEnv


type Env
    = Development
    | Production


{-| The current execution environment.
It might look like this code is broken, but it works using _magic_.
-}
mode : Env
mode =
    case LamderaEnv.mode of
        LamderaEnv.Development ->
            Development

        LamderaEnv.Production ->
            Production


auth0Url : String
auth0Url =
    "https://dev-vtcno-ac.us.auth0.com"
