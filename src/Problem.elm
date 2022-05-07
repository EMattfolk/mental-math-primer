module Problem exposing (..)

import Dict
import Random exposing (Generator)
import Types exposing (..)


{-| TODO: Generalize :O
-}
offsets : Generator ( Int, Int )
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
    String.replace "+ -" "- " <|
        case fragment of
            Addition f1 f2 ->
                toString f1 ++ " + " ++ toString f2

            Multiplication f1 f2 ->
                toString f1 ++ " ⋅ " ++ toString f2

            SquareRoot f ->
                "√" ++ toString f

            Power f1 f2 ->
                toString f1 ++ toSuperscript (toString f2)

            Constant c ->
                String.fromInt c


nestedFragmentGenerator :
    Int
    -> (Fragment -> Fragment -> Fragment)
    -> Generator Fragment
    -> Generator Fragment
nestedFragmentGenerator atoms operand termGenerator =
    if atoms <= 1 then
        termGenerator

    else
        Random.map2 operand termGenerator <|
            nestedFragmentGenerator
                (atoms - 1)
                operand
                termGenerator


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
                            ( 0.75, Random.int 1 30 )
                            [ ( 0.25, Random.int -30 -1 ) ]

                Medium ->
                    Random.andThen identity <|
                        Random.weighted
                            ( 0.75, Random.int 1 40 )
                            [ ( 0.25, Random.int -40 -1 ) ]

                Hard ->
                    Random.andThen identity <|
                        Random.weighted
                            ( 0.75, Random.int 1 50 )
                            [ ( 0.25, Random.int -50 -1 ) ]

                Impossible ->
                    Random.andThen identity <|
                        Random.weighted
                            ( 0.75, Random.int 1 99 )
                            [ ( 0.25, Random.int -99 -1 ) ]

        atoms =
            case difficulty of
                Trivial ->
                    2

                Easy ->
                    2

                Medium ->
                    3

                Hard ->
                    4

                Impossible ->
                    5

        fragment =
            nestedFragmentGenerator atoms Addition (Random.map Constant n)
    in
    fragment
        |> Random.andThen toProblemGenerator


mulProblem : Difficulty -> Generator Problem
mulProblem difficulty =
    let
        n =
            case difficulty of
                Trivial ->
                    Random.int 1 10

                Easy ->
                    Random.int 1 15

                Medium ->
                    Random.int 1 15

                Hard ->
                    Random.int 1 20

                Impossible ->
                    Random.int 1 20

        atoms =
            case difficulty of
                Trivial ->
                    1

                Easy ->
                    1

                Medium ->
                    2

                Hard ->
                    2

                Impossible ->
                    3

        fragment =
            nestedFragmentGenerator atoms
                Addition
                (Random.map2 (\a b -> Multiplication (Constant a) (Constant b)) n n)
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


boundedExponent : Int -> Generator Fragment
boundedExponent bound =
    let
        base =
            Random.int 2 16

        exponent =
            Random.int 2 11
    in
    Random.pair base exponent
        |> Random.andThen
            (\( b, e ) ->
                if b ^ e <= bound then
                    Random.constant (Power (Constant b) (Constant e))

                else
                    boundedExponent bound
            )


exponentProblem : Difficulty -> Generator Problem
exponentProblem difficulty =
    let
        fragment =
            case difficulty of
                Trivial ->
                    boundedExponent 16

                Easy ->
                    boundedExponent 64

                Medium ->
                    boundedExponent 128

                Hard ->
                    boundedExponent 512

                Impossible ->
                    boundedExponent 2048
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


difficultyValue : Difficulty -> Int
difficultyValue difficulty =
    case difficulty of
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


difficultyScore : Difficulty -> { single : Int, set : Int }
difficultyScore difficulty =
    { single = difficultyValue difficulty + 1
    , set = (difficultyValue difficulty + 1) * 5
    }


compareDifficulty : Difficulty -> Difficulty -> Order
compareDifficulty d1 d2 =
    compare (difficultyValue d1) (difficultyValue d2)


emptyProgress : Progress
emptyProgress =
    { addSub = Nothing
    , mul = Nothing
    , sqrt = Nothing
    , exponent = Nothing
    , score = 0
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
    , score = p1.score + p2.score
    }
