module Backend exposing (app, init)

import Lamdera exposing (ClientId, SessionId, broadcast, sendToFrontend)
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


permutations : Int -> ( Int, Int, Int )
permutations i =
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
                [ a + b - 2, a + b, a + b + 2 ]
                    |> permute (permutations p)
                    |> List.map String.fromInt
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
        CounterIncremented ->
            let
                newCounter =
                    model.counter + 1
            in
            ( { model | counter = newCounter }
            , broadcast (CounterNewValue newCounter clientId)
            )


subscriptions : Model -> Sub BackendMsg
subscriptions _ =
    Sub.batch
        [ Lamdera.onConnect ClientConnected
        ]
