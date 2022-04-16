module Auth exposing (..)

import Auth0 exposing (Auth0Config, auth0AuthorizeURL)


{-| Url to auth service
-}
url : String
url =
    auth0AuthorizeURL
        (Auth0Config "https://dev-vtcno-ac.us.auth0.com" "pJsQXQKLDptayHhSm3vt42jOJPYFx1xT")
        "token"
        "https://example.com"
        [ "openid", "name", "email" ]
        (Just "google-oauth2")
