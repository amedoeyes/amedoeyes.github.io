module Commands exposing (Command, cat, cd, clear, echo, help, ls, pwd, tree)

import FS
import Http
import IO exposing (Output)
import Json.Decode as Decode
import RichText


type alias Command model msg =
    { minArgs : Int
    , maxArgs : Maybe Int
    , run : List String -> model -> ( model, Cmd msg )
    }


echo : Command { model | output : List Output } msg
echo =
    { minArgs = 0
    , maxArgs = Nothing
    , run =
        \args model ->
            let
                output =
                    IO.Text (args |> List.map (\a -> RichText.Plain a) |> List.intersperse (RichText.Plain " ") |> RichText.Group |> RichText.Line)
                        |> List.singleton
                        |> List.append model.output
            in
            ( { model | output = output }, Cmd.none )
    }


clear : Command { model | output : List Output } msg
clear =
    { minArgs = 0
    , maxArgs = Just 0
    , run = \_ model -> ( { model | output = [] }, Cmd.none )
    }


pwd : Command { model | output : List Output, pwd : String } msg
pwd =
    { minArgs = 0
    , maxArgs = Nothing
    , run =
        \_ model ->
            let
                output =
                    IO.Text (RichText.Line (RichText.Plain model.pwd))
                        |> List.singleton
                        |> List.append model.output
            in
            ( { model | output = output }, Cmd.none )
    }


cd : Command { model | output : List Output, fileSystem : FS.Node, pwd : String } msg
cd =
    { minArgs = 0
    , maxArgs = Just 1
    , run =
        \args model ->
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
                            case FS.resolvePath newPath model.fileSystem of
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
    }


ls : Command { model | output : List Output, fileSystem : FS.Node, pwd : String } msg
ls =
    { minArgs = 0
    , maxArgs = Just 1
    , run =
        \args model ->
            let
                output =
                    case args of
                        [] ->
                            case FS.resolvePath model.pwd model.fileSystem of
                                Nothing ->
                                    IO.Text (RichText.Plain ([ "Error:", "'" ++ model.pwd ++ "'", "no such file or directory" ] |> String.join " "))
                                        |> List.singleton
                                        |> List.append model.output

                                Just node ->
                                    IO.Text (FS.list node)
                                        |> List.singleton
                                        |> List.append model.output

                        path :: _ ->
                            case FS.resolvePath (model.pwd ++ "/" ++ path) model.fileSystem of
                                Nothing ->
                                    IO.Text (RichText.Plain ([ "Error:", "'" ++ model.pwd ++ "'", "no such file or directory" ] |> String.join " "))
                                        |> List.singleton
                                        |> List.append model.output

                                Just node ->
                                    IO.Text (FS.list node)
                                        |> List.singleton
                                        |> List.append model.output
            in
            ( { model | output = output }, Cmd.none )
    }


tree : Command { model | output : List Output, fileSystem : FS.Node, pwd : String } msg
tree =
    { minArgs = 0
    , maxArgs = Just 1
    , run =
        \args model ->
            let
                output =
                    case args of
                        [] ->
                            case FS.resolvePath model.pwd model.fileSystem of
                                Nothing ->
                                    IO.Text (RichText.Line (RichText.Plain ([ "Error: the directory", "'" ++ model.pwd ++ "'", "does not exist" ] |> String.join " ")))
                                        |> List.singleton
                                        |> List.append model.output

                                Just node ->
                                    FS.tree node
                                        |> IO.Text
                                        |> List.singleton
                                        |> List.append model.output

                        path :: _ ->
                            case FS.resolvePath (model.pwd ++ "/" ++ path) model.fileSystem of
                                Nothing ->
                                    IO.Text (RichText.Line (RichText.Plain ([ "Error: the directory", "'" ++ path ++ "'", "does not exist" ] |> String.join " ")))
                                        |> List.singleton
                                        |> List.append model.output

                                Just node ->
                                    case node of
                                        FS.File _ _ ->
                                            IO.Text (RichText.Line (RichText.Plain ([ "Error:", "'" ++ path ++ "'", "is not a directory" ] |> String.join " ")))
                                                |> List.singleton
                                                |> List.append model.output

                                        FS.Directory _ _ ->
                                            FS.tree node
                                                |> IO.Text
                                                |> List.singleton
                                                |> List.append model.output
            in
            ( { model | output = output }, Cmd.none )
    }


cat : (Result Http.Error String -> msg) -> Command { model | output : List Output, fileSystem : FS.Node, pwd : String } msg
cat gotImage =
    { minArgs = 0
    , maxArgs = Nothing
    , run =
        \args model ->
            let
                output =
                    args
                        |> List.map
                            (\path ->
                                case FS.resolvePath (model.pwd ++ "/" ++ path) model.fileSystem of
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
                    , expect = Http.expectJson gotImage (Decode.index 0 (Decode.field "url" Decode.string))
                    }
                )

            else
                ( { model | output = output }, Cmd.none )
    }


help : Command { model | output : List Output } msg
help =
    let
        commands =
            [ ( "echo", "[ARGS]...", "display a line of text" )
            , ( "clear", "", "clear the terminal screen" )
            , ( "pwd", "", "output the current working directory" )
            , ( "cd", "[DIRECTORY]", "change directory" )
            , ( "ls", "[FILE]", "list directory contents" )
            , ( "tree", "[FILE]", "list contents of directories in a tree-like format" )
            , ( "cat", "FILE...", "concatenate files and output them" )
            , ( "help", "[COMMAND]", "display this help message" )
            ]
    in
    { minArgs = 0
    , maxArgs = Just 1
    , run =
        \args model ->
            let
                output =
                    case args of
                        [] ->
                            let
                                values =
                                    commands |> List.sortBy (\( name, _, _ ) -> name)

                                maxLen =
                                    values |> List.map (\( name, arguments, _ ) -> String.length name + String.length arguments + 1) |> List.maximum |> Maybe.withDefault 0
                            in
                            values
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
    }
