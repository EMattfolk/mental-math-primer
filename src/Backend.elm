module Backend exposing (app, init)

import Lamdera exposing (ClientId, SessionId, sendToFrontend)
import Random exposing (Generator)
import Types exposing (..)


type alias Model =
    BackendModel


app : BackendApp
app =
    Lamdera.backend
        { init = init
        , update = update
        , updateFromFrontend = updateFromFrontend
        , subscriptions = subscriptions
        }


init : ( Model, Cmd BackendMsg )
init =
    ( { counter = 0 }, Cmd.none )


permutation3 : Int -> ( Int, Int, Int )
permutation3 i =
    case i of
        0 ->
            ( 0, 1, 2 )

        1 ->
            ( 0, 2, 1 )

        2 ->
            ( 1, 0, 2 )

        3 ->
            ( 1, 2, 0 )

        4 ->
            ( 2, 0, 1 )

        _ ->
            ( 2, 1, 0 )


permutationToCorrect : ( Int, Int, Int ) -> Int
permutationToCorrect ( i0, i1, i2 ) =
    if i0 == 0 then
        0

    else if i1 == 0 then
        1

    else
        2


permute : ( Int, Int, Int ) -> List Int -> List Int
permute ( i0, i1, i2 ) list =
    case list of
        [ e0, e1, e2 ] ->
            let
                select =
                    \i ->
                        case i of
                            0 ->
                                e0

                            1 ->
                                e1

                            _ ->
                                e2
            in
            [ i0, i1, i2 ] |> List.map select

        _ ->
            []


randomProblem : Generator Problem
randomProblem =
    let
        t1 =
            Random.int 1 5

        t2 =
            Random.int 1 5

        permutation =
            Random.int 0 5
    in
    Random.map3
        (\a b p ->
            { statement = String.fromInt a ++ " + " ++ String.fromInt b
            , choices =
                -- The correct one is at index 0
                [ a + b, a + b - 2, a + b + 2 ]
                    |> permute (permutation3 p)
                    |> List.map String.fromInt
            , correct = permutation3 p |> permutationToCorrect
            , remainingTime = 9.999 -- Should be 10, but we avoid flicker this way
            }
        )
        t1
        t2
        permutation


update : BackendMsg -> Model -> ( Model, Cmd BackendMsg )
update msg model =
    case msg of
        ClientConnected _ clientId ->
            ( model
            , Random.generate (SendProblem clientId) randomProblem
            )

        SendProblem clientId problem ->
            ( model
            , sendToFrontend clientId <|
                SetProblem problem
            )


updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
updateFromFrontend _ clientId msg model =
    case msg of
        GetNewProblem ->
            ( model
            , Random.generate (SendProblem clientId) randomProblem
            )


subscriptions : Model -> Sub BackendMsg
subscriptions _ =
    Sub.batch
        [ Lamdera.onConnect ClientConnected
        ]
