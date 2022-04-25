module Problem exposing (..)

import Dict
import Random exposing (Generator)
import Types exposing (..)


{-| TODO: Generalize :O
-}
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
    | Multiplication Fragment Fragment
    | SquareRoot Fragment
    | Power Fragment Fragment
    | Constant Int


eval : Fragment -> Int
eval fragment =
    case fragment of
        Addition f1 f2 ->
            eval f1 + eval f2

        Multiplication f1 f2 ->
            eval f1 * eval f2

        SquareRoot f ->
            f |> eval |> toFloat |> sqrt |> floor

        Power f1 f2 ->
            eval f1 ^ eval f2

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

        Multiplication f1 f2 ->
            toString f1 ++ " * " ++ toString f2

        SquareRoot f ->
            "√" ++ toString f

        Power f1 f2 ->
            toString f1 ++ toSuperscript (toString f2)

        Constant c ->
            String.fromInt c


toSuperscript : String -> String
toSuperscript s =
    let
        tr =
            Dict.fromList
                [ ( '0', '⁰' )
                , ( '1', '¹' )
                , ( '2', '²' )
                , ( '3', '³' )
                , ( '4', '⁴' )
                , ( '5', '⁵' )
                , ( '6', '⁶' )
                , ( '7', '⁷' )
                , ( '8', '⁸' )
                , ( '9', '⁹' )
                ]
    in
    String.map (\c -> tr |> Dict.get c |> Maybe.withDefault c) s


emptyProblem : Problem
emptyProblem =
    { statement = ""
    , choices = []
    , correct = 0
    , remainingTime = 10.0
    }


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


addSubProblem : Difficulty -> Generator Problem
addSubProblem difficulty =
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


mulProblem : Difficulty -> Generator Problem
mulProblem difficulty =
    let
        n =
            case difficulty of
                Trivial ->
                    Random.int 1 5

                Easy ->
                    Random.int 1 7

                Medium ->
                    Random.int 1 9

                Hard ->
                    Random.int 1 12

                Impossible ->
                    Random.int 1 16

        fragment =
            Random.map2 (\a b -> Multiplication (Constant a) (Constant b)) n n
    in
    fragment
        |> Random.andThen toProblemGenerator


sqrtProblem : Difficulty -> Generator Problem
sqrtProblem difficulty =
    let
        n =
            case difficulty of
                Trivial ->
                    Random.int 1 15

                Easy ->
                    Random.int 1 15

                Medium ->
                    Random.int 1 15

                Hard ->
                    Random.int 1 15

                Impossible ->
                    Random.int 1 15

        fragment =
            Random.map (\a -> SquareRoot (Constant (a ^ 2))) n
    in
    fragment
        |> Random.andThen toProblemGenerator


exponentProblem : Difficulty -> Generator Problem
exponentProblem difficulty =
    let
        n =
            case difficulty of
                Trivial ->
                    Random.int 1 4

                Easy ->
                    Random.int 1 6

                Medium ->
                    Random.int 1 10

                Hard ->
                    Random.int 1 12

                Impossible ->
                    Random.int 1 16

        exp =
            Random.int 2 4

        fragment =
            Random.map2 (\a b -> Power (Constant a) (Constant b)) n exp
    in
    fragment
        |> Random.andThen toProblemGenerator


randomProblem : ProblemType -> Difficulty -> Generator Problem
randomProblem problemType =
    case problemType of
        AddSub ->
            addSubProblem

        Mul ->
            mulProblem

        Sqrt ->
            sqrtProblem

        Exponent ->
            exponentProblem


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


emptyProgress : Progress
emptyProgress =
    { addSub = Nothing
    , mul = Nothing
    , sqrt = Nothing
    , exponent = Nothing
    }


{-| Merge two progresses, keeping the highest values
-}
mergeProgress : Progress -> Progress -> Progress
mergeProgress p1 p2 =
    let
        mergeMaybeDifficulty md1 md2 =
            case ( md1, md2 ) of
                ( Nothing, Nothing ) ->
                    Nothing

                ( Just _, Nothing ) ->
                    md1

                ( Nothing, Just _ ) ->
                    md2

                ( Just d1, Just d2 ) ->
                    Just <|
                        if compareDifficulty d1 d2 == GT then
                            d1

                        else
                            d2
    in
    { addSub = mergeMaybeDifficulty p1.addSub p2.addSub
    , mul = mergeMaybeDifficulty p1.mul p2.mul
    , sqrt = mergeMaybeDifficulty p1.sqrt p2.sqrt
    , exponent = mergeMaybeDifficulty p1.exponent p2.exponent
    }
