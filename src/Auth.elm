module Auth exposing (..)

import Auth0 exposing (Auth0Config, auth0AuthorizeURL)
import Config exposing (Env(..))


baseUrl : String
baseUrl =
    "https://dev-vtcno-ac.us.auth0.com"


userinfoUrl : String
userinfoUrl =
    baseUrl ++ "/userinfo"


authorizeUrl : String
authorizeUrl =
    auth0AuthorizeURL
        (Auth0Config baseUrl "pJsQXQKLDptayHhSm3vt42jOJPYFx1xT")
        "token"
        (case Config.mode of
            Development ->
                "http://localhost:8000/authorize"

            Production ->
                "https://mental-math-primer.lamdera.app/authorize"
        )
        [ "openid", "name", "email" ]
        (Just "google-oauth2")
