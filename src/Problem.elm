module Problem exposing (..)

import Random exposing (Generator)
import Types exposing (..)


offsets : Random.Generator ( Int, Int )
offsets =
    Random.pair (Random.int -5 5) (Random.int -5 5)
        |> Random.andThen
            (\( o1, o2 ) ->
                if o1 == o2 || o1 == 0 || o2 == 0 then
                    Random.lazy (\_ -> offsets)

                else
                    Random.constant ( o1, o2 )
            )


{-| A simple syntax tree for problem descriptions.
-}
type Fragment
    = Addition Fragment Fragment
    | Constant Int


eval : Fragment -> Int
eval fragment =
    case fragment of
        Addition f1 f2 ->
            eval f1 + eval f2

        Constant c ->
            c


toString : Fragment -> String
toString fragment =
    case fragment of
        Addition f1 (Constant c) ->
            toString f1
                ++ (if c < 0 then
                        " - " ++ String.fromInt -c

                    else
                        " + " ++ String.fromInt c
                   )

        Addition f1 f2 ->
            toString f1 ++ " + " ++ toString f2

        Constant c ->
            String.fromInt c


toProblemGenerator : Fragment -> Generator Problem
toProblemGenerator fragment =
    Random.map2
        (\p ( o1, o2 ) ->
            { statement = fragment |> toString
            , choices =
                let
                    v =
                        eval fragment
                in
                -- The correct one is at index 0
                List.map2 (+) [ v, v, v ] [ 0, o1, o2 ]
                    |> permute (permutation3 p)
                    |> List.map String.fromInt
            , correct = permutation3 p |> permutationToCorrect
            , remainingTime = 9.999 -- Should be 10, but we avoid flicker this way
            }
        )
        (Random.int 0 5)
        offsets


randomProblem : Difficulty -> Generator Problem
randomProblem difficulty =
    let
        n =
            case difficulty of
                Trivial ->
                    Random.int 1 15

                Easy ->
                    Random.andThen identity <|
                        Random.weighted
                            ( 0.75, Random.int 1 15 )
                            [ ( 0.25, Random.int -15 -1 ) ]

                Medium ->
                    Random.andThen identity <|
                        Random.weighted
                            ( 0.75, Random.int 1 50 )
                            [ ( 0.25, Random.int -50 -1 ) ]

                Hard ->
                    Random.andThen identity <|
                        Random.weighted
                            ( 0.75, Random.int 1 150 )
                            [ ( 0.25, Random.int -150 -1 ) ]

                Impossible ->
                    Random.andThen identity <|
                        Random.weighted
                            ( 0.75, Random.int 1 500 )
                            [ ( 0.25, Random.int -500 -1 ) ]

        fragment =
            Random.map2 (\a b -> Addition (Constant a) (Constant b)) n n
    in
    fragment
        |> Random.andThen toProblemGenerator


{-| A "list" of the permutations of the tuple (0, 1, 2)
-}
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


{-| Get the correct index for a given permutation.

The correct index is always where the 0 element is.

-}
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


compareDifficulty : Difficulty -> Difficulty -> Order
compareDifficulty d1 d2 =
    let
        value d =
            case d of
                Trivial ->
                    0

                Easy ->
                    1

                Medium ->
                    2

                Hard ->
                    3

                Impossible ->
                    4
    in
    compare (value d1) (value d2)
