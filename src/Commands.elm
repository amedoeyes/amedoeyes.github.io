module Commands exposing (Command, cat, cd, clear, download, echo, help, ls, open, pwd, tree)

import FS
import Http
import IO exposing (Output)
import Json.Decode as Decode
import RichText


type alias Command model msg =
    List String -> model -> ( model, Cmd msg )


echo : Command { model | output : List Output } msg
echo args model =
    let
        output =
            IO.Text (args |> List.map (\a -> RichText.Plain a) |> List.intersperse (RichText.Plain " ") |> RichText.Group |> RichText.Line)
                |> List.singleton
                |> List.append model.output
    in
    ( { model | output = output }, Cmd.none )


clear : Command { model | output : List Output } msg
clear _ model =
    ( { model | output = [] }, Cmd.none )


pwd : Command { model | pwd : String, output : List Output } msg
pwd _ model =
    let
        output =
            IO.Text (RichText.Line (RichText.Plain model.pwd))
                |> List.singleton
                |> List.append model.output
    in
    ( { model | output = output }, Cmd.none )


cd : FS.Node -> Command { model | pwd : String, output : List Output } msg
cd fileSystem args model =
    let
        ( pwd_, output ) =
            case args of
                [] ->
                    ( "/", model.output )

                path :: _ ->
                    let
                        newPath =
                            if String.startsWith "/" path then
                                path

                            else
                                model.pwd ++ "/" ++ path
                    in
                    case FS.resolvePath newPath fileSystem of
                        Nothing ->
                            ( model.pwd
                            , IO.Text (RichText.Line (RichText.Plain ([ "Error: the directory", "'" ++ path ++ "'", "does not exist" ] |> String.join " ")))
                                |> List.singleton
                                |> List.append model.output
                            )

                        Just node ->
                            case node of
                                FS.File _ _ ->
                                    ( model.pwd
                                    , IO.Text (RichText.Line (RichText.Plain ([ "Error:", "'" ++ path ++ "'", "is not a directory" ] |> String.join " ")))
                                        |> List.singleton
                                        |> List.append model.output
                                    )

                                FS.Directory _ _ ->
                                    ( "/" ++ (FS.normalizePath newPath |> String.join "/"), model.output )
    in
    ( { model | output = output, pwd = pwd_ }, Cmd.none )


ls : FS.Node -> Command { model | pwd : String, output : List Output } msg
ls fileSystem args model =
    let
        aux path =
            case FS.resolvePath path fileSystem of
                Nothing ->
                    RichText.Line (RichText.Plain ([ "Error:", "'" ++ model.pwd ++ "'", "no such file or directory" ] |> String.join " "))

                Just node ->
                    FS.list node

        output =
            case args of
                [] ->
                    aux model.pwd
                        |> IO.Text
                        |> List.singleton
                        |> List.append model.output

                path :: [] ->
                    aux (model.pwd ++ "/" ++ path)
                        |> IO.Text
                        |> List.singleton
                        |> List.append model.output

                paths ->
                    paths
                        |> List.map (\p -> RichText.Group [ RichText.Line (RichText.Plain (p ++ ":")), aux p ])
                        |> List.intersperse (RichText.Line (RichText.Plain ""))
                        |> List.map (\l -> IO.Text l)
                        |> List.append model.output
    in
    ( { model | output = output }, Cmd.none )


tree : FS.Node -> Command { model | pwd : String, output : List Output } msg
tree fileSystem args model =
    let
        aux path =
            case FS.resolvePath path fileSystem of
                Nothing ->
                    RichText.Line (RichText.Plain ([ "Error: the directory", "'" ++ path ++ "'", "does not exist" ] |> String.join " "))

                Just node ->
                    case node of
                        FS.File _ _ ->
                            RichText.Line (RichText.Plain ([ "Error:", "'" ++ path ++ "'", "is not a directory" ] |> String.join " "))

                        FS.Directory _ _ ->
                            FS.tree node

        output =
            case args of
                [] ->
                    aux model.pwd
                        |> IO.Text
                        |> List.singleton
                        |> List.append model.output

                path :: [] ->
                    aux (model.pwd ++ "/" ++ path)
                        |> IO.Text
                        |> List.singleton
                        |> List.append model.output

                paths ->
                    paths
                        |> List.map aux
                        |> List.intersperse (RichText.Line (RichText.Plain ""))
                        |> List.map (\l -> IO.Text l)
                        |> List.append model.output
    in
    ( { model | output = output }, Cmd.none )


cat : FS.Node -> (String -> msg) -> Command { model | pwd : String, output : List Output } msg
cat fileSystem gotImage args model =
    let
        output =
            args
                |> List.map
                    (\path ->
                        case FS.resolvePath (model.pwd ++ "/" ++ path) fileSystem of
                            Nothing ->
                                IO.Text (RichText.Line (RichText.Plain ([ "Error: file", "'" ++ path ++ "'", "does not exist" ] |> String.join " ")))

                            Just node ->
                                case node of
                                    FS.File _ content ->
                                        content |> IO.Text

                                    FS.Directory _ _ ->
                                        IO.Text (RichText.Line (RichText.Plain ([ "Error:", "'" ++ path ++ "'", "is a directory" ] |> String.join " ")))
                    )
                |> List.append model.output
    in
    if List.isEmpty args then
        ( model
        , Http.get
            { url = "https://api.thecatapi.com/v1/images/search"
            , expect =
                Http.expectJson
                    (\res ->
                        res |> Result.withDefault "https://placehold.co/300x200?text=:3" |> gotImage
                    )
                    (Decode.index 0 (Decode.field "url" Decode.string))
            }
        )

    else
        ( { model | output = output }, Cmd.none )


open : FS.Node -> Command { model | pwd : String, output : List Output } msg
open fileSystem args model =
    let
        ( output, cmd ) =
            case args of
                [] ->
                    RichText.Line (RichText.Plain "Error: expected file")
                        |> IO.Text
                        |> List.singleton
                        |> List.append model.output
                        |> (\o -> ( o, Cmd.none ))

                path :: _ ->
                    case FS.resolvePath path fileSystem of
                        Nothing ->
                            RichText.Line (RichText.Plain ([ "Error: the file", "'" ++ path ++ "'", "does not exist" ] |> String.join " "))
                                |> IO.Text
                                |> List.singleton
                                |> List.append model.output
                                |> (\o -> ( o, Cmd.none ))

                        Just node ->
                            case node of
                                FS.File _ _ ->
                                    ( model.output, FS.open node )

                                FS.Directory _ _ ->
                                    RichText.Line (RichText.Plain ([ "Error:", "'" ++ path ++ "'", "is not a file" ] |> String.join " "))
                                        |> IO.Text
                                        |> List.singleton
                                        |> List.append model.output
                                        |> (\o -> ( o, Cmd.none ))
    in
    ( { model | output = output }, cmd )


download : FS.Node -> Command { model | pwd : String, output : List Output } msg
download fileSystem args model =
    let
        ( output, cmd ) =
            case args of
                [] ->
                    RichText.Line (RichText.Plain "Error: expected file")
                        |> IO.Text
                        |> List.singleton
                        |> List.append model.output
                        |> (\o -> ( o, Cmd.none ))

                path :: _ ->
                    case FS.resolvePath path fileSystem of
                        Nothing ->
                            RichText.Line (RichText.Plain ([ "Error: the file", "'" ++ path ++ "'", "does not exist" ] |> String.join " "))
                                |> IO.Text
                                |> List.singleton
                                |> List.append model.output
                                |> (\o -> ( o, Cmd.none ))

                        Just node ->
                            case node of
                                FS.File _ _ ->
                                    ( model.output, FS.download node )

                                FS.Directory _ _ ->
                                    RichText.Line (RichText.Plain ([ "Error:", "'" ++ path ++ "'", "is not a file" ] |> String.join " "))
                                        |> IO.Text
                                        |> List.singleton
                                        |> List.append model.output
                                        |> (\o -> ( o, Cmd.none ))
    in
    ( { model | output = output }, cmd )


help : Command { model | output : List Output } msg
help args model =
    let
        commands =
            [ ( "echo", "[ARGS]...", "display a line of text" )
            , ( "clear", "", "clear the terminal screen" )
            , ( "pwd", "", "output the current working directory" )
            , ( "cd", "[DIRECTORY]", "change directory" )
            , ( "ls", "[FILE..]", "list directory contents" )
            , ( "tree", "[FILE..]", "list contents of directories in a tree-like format" )
            , ( "cat", "[FILE]...", "concatenate files and output them" )
            , ( "open", "FILE", "open file" )
            , ( "download", "FILE", "download file" )
            , ( "help", "[COMMAND]", "display this help message" )
            ]

        maxLen =
            commands |> List.map (\( name, arguments, _ ) -> String.length name + String.length arguments + 1) |> List.maximum |> Maybe.withDefault 0
    in
    let
        output =
            case args of
                [] ->
                    commands
                        |> List.map
                            (\( name, arguments, description ) ->
                                IO.Text
                                    (RichText.Line
                                        (RichText.Group
                                            [ RichText.Styled [ RichText.Bold ] (RichText.Plain ([ name, arguments ] |> String.join " "))
                                            , RichText.Plain (String.repeat (maxLen - (String.length name + String.length arguments + 1)) " " ++ "  " ++ description)
                                            ]
                                        )
                                    )
                            )
                        |> List.append model.output

                name :: _ ->
                    case commands |> List.filter (\( name_, _, _ ) -> name_ == name) |> List.head of
                        Just ( name_, arguments, description ) ->
                            [ IO.Text (RichText.Line (RichText.Plain description))
                            , IO.Text (RichText.Line (RichText.Plain ""))
                            , IO.Text (RichText.Line (RichText.Plain ([ "Usage:", name_, arguments ] |> String.join " ")))
                            ]
                                |> List.append model.output

                        Nothing ->
                            IO.Text (RichText.Line (RichText.Plain ([ "Error:", "'" ++ name ++ "'", "does not exist" ] |> String.join " ")))
                                |> List.singleton
                                |> List.append model.output
    in
    ( { model | output = output }, Cmd.none )
