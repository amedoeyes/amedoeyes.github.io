module FS exposing (Node(..), child, isDirectory, isFile, list, name, normalizePath, resolvePath, tree)

import RichText exposing (Text)


type Node
    = File String (List (List Text))
    | Directory String (List Node)


name : Node -> String
name node =
    case node of
        File name_ _ ->
            name_

        Directory name_ _ ->
            if String.isEmpty name_ then
                "/"

            else
                name_


isFile : Node -> Bool
isFile node =
    case node of
        File _ _ ->
            True

        Directory _ _ ->
            False


isDirectory : Node -> Bool
isDirectory node =
    case node of
        File _ _ ->
            False

        Directory _ _ ->
            True


child : String -> Node -> Maybe Node
child name_ node =
    case node of
        File _ _ ->
            Nothing

        Directory _ children ->
            children |> List.filter (\c -> name c == name_) |> List.head


normalizePath : String -> List String
normalizePath path =
    path
        |> String.split "/"
        |> List.filter (String.isEmpty >> not)
        |> List.foldl
            (\p acc ->
                case p of
                    "" ->
                        acc

                    "." ->
                        acc

                    ".." ->
                        acc |> List.drop 1

                    other ->
                        other :: acc
            )
            []
        |> List.reverse


resolvePath : String -> Node -> Maybe Node
resolvePath path root =
    normalizePath path |> List.foldl (\p acc -> acc |> Maybe.andThen (child p)) (Just root)


list : Node -> List Text
list root =
    case root of
        File name_ _ ->
            [ RichText.Plain name_ ]

        Directory _ children ->
            children |> List.sortBy name |> List.map name |> List.map RichText.Plain |> List.intersperse (RichText.Plain "  ")


tree : Node -> List Text
tree root =
    let
        aux node depth ancestors isLast =
            let
                prefix =
                    ancestors
                        |> List.map
                            (\b ->
                                if b then
                                    "    "

                                else
                                    "│   "
                            )
                        |> String.concat

                branch =
                    if depth == 0 then
                        ""

                    else if isLast then
                        "└── "

                    else
                        "├── "

                line =
                    RichText.Plain (prefix ++ branch ++ name node)

                childAncestors =
                    if depth == 0 then
                        []

                    else
                        ancestors ++ [ isLast ]

                childLines =
                    case node of
                        File _ _ ->
                            []

                        Directory _ children ->
                            let
                                count =
                                    List.length children
                            in
                            children
                                |> List.sortBy name
                                |> List.indexedMap (\i c -> aux c (depth + 1) childAncestors (i == count - 1))
                                |> List.concat
            in
            line :: childLines
    in
    aux root 0 [] False
