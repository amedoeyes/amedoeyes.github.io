module Main exposing (..)

import Browser
import Browser.Dom as Dom
import Browser.Events exposing (onKeyPress)
import Dict exposing (Dict)
import FS
import Html exposing (Attribute, Html, div, img, main_, text, textarea)
import Html.Attributes exposing (autofocus, class, id, src, value)
import Html.Events exposing (onInput, preventDefaultOn)
import Http
import Json.Decode as Decode
import RichText
import Task


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , subscriptions = subscriptions
        , view = view
        , update = update
        }


type Msg
    = UpdateInput String
    | Submit
    | GotImage (Result Http.Error String)
    | ScrollDone (Result Dom.Error ())
    | FocusInput
    | NoOp


type alias Model =
    { input : String
    , history : List String
    , output : List Output
    , pwd : String
    }


type Output
    = Text RichText.RichText
    | Image String


type alias Command =
    { name : String
    , arguments : String
    , description : String
    , minArgs : Int
    , maxArgs : Maybe Int
    , run : List String -> Model -> ( Model, Cmd Msg )
    }


prompt : RichText.RichText
prompt =
    RichText.Styled [ RichText.Color "#606060" ] (RichText.Plain "$ ")


fileSystem : FS.Node
fileSystem =
    FS.Directory ""
        [ FS.File "hello.txt" (RichText.Line (RichText.Plain "Hello world!"))
        , FS.File "hello_lines.txt" (RichText.Group [ RichText.Line (RichText.Plain "Hello"), RichText.Line (RichText.Plain "world!") ])
        , FS.File "file1.txt" (RichText.Line (RichText.Plain "file 1"))
        , FS.File "file2.txt" (RichText.Line (RichText.Plain "file 2"))
        , FS.Directory "dir"
            [ FS.File "file1.txt" (RichText.Line (RichText.Plain "file 1"))
            , FS.File "file2.txt" (RichText.Line (RichText.Plain "file 2"))
            , FS.Directory "subdir"
                [ FS.File "file1.txt" (RichText.Line (RichText.Plain "file 1"))
                ]
            ]
        ]


commands : Dict String Command
commands =
    Dict.fromList
        [ ( "echo"
          , { name = "echo"
            , arguments = "[ARGS]..."
            , description = "display a line of text"
            , minArgs = 0
            , maxArgs = Nothing
            , run =
                \args model ->
                    let
                        output =
                            Text (args |> List.map (\a -> RichText.Plain a) |> List.intersperse (RichText.Plain " ") |> RichText.Group |> RichText.Line)
                                |> List.singleton
                                |> List.append model.output
                    in
                    ( { model | output = output }, Cmd.none )
            }
          )
        , ( "clear"
          , { name = "clear"
            , arguments = ""
            , description = "clear the terminal screen"
            , minArgs = 0
            , maxArgs = Just 0
            , run = \_ model -> ( { model | output = [] }, Cmd.none )
            }
          )
        , ( "pwd"
          , { name = "pwd"
            , arguments = ""
            , description = "output the current working directory"
            , minArgs = 0
            , maxArgs = Nothing
            , run =
                \_ model ->
                    let
                        output =
                            Text (RichText.Line (RichText.Plain model.pwd))
                                |> List.singleton
                                |> List.append model.output
                    in
                    ( { model | output = output }, Cmd.none )
            }
          )
        , ( "cd"
          , { name = "cd"
            , arguments = "[DIRECTORY]"
            , description = "change directory"
            , minArgs = 0
            , maxArgs = Just 1
            , run =
                \args model ->
                    let
                        ( pwd, output ) =
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
                                            , Text (RichText.Line (RichText.Plain ([ "Error: the directory", "'" ++ path ++ "'", "does not exist" ] |> String.join " ")))
                                                |> List.singleton
                                                |> List.append model.output
                                            )

                                        Just node ->
                                            case node of
                                                FS.File _ _ ->
                                                    ( model.pwd
                                                    , Text (RichText.Line (RichText.Plain ([ "Error:", "'" ++ path ++ "'", "is not a directory" ] |> String.join " ")))
                                                        |> List.singleton
                                                        |> List.append model.output
                                                    )

                                                FS.Directory _ _ ->
                                                    ( "/" ++ (FS.normalizePath newPath |> String.join "/"), model.output )
                    in
                    ( { model | output = output, pwd = pwd }, Cmd.none )
            }
          )
        , ( "ls"
          , { name = "ls"
            , arguments = "[FILE]"
            , description = "list directory contents"
            , minArgs = 0
            , maxArgs = Just 1
            , run =
                \args model ->
                    let
                        output =
                            case args of
                                [] ->
                                    case FS.resolvePath model.pwd fileSystem of
                                        Nothing ->
                                            Text (RichText.Plain ([ "Error:", "'" ++ model.pwd ++ "'", "no such file or directory" ] |> String.join " "))
                                                |> List.singleton
                                                |> List.append model.output

                                        Just node ->
                                            Text (FS.list node)
                                                |> List.singleton
                                                |> List.append model.output

                                path :: _ ->
                                    case FS.resolvePath (model.pwd ++ "/" ++ path) fileSystem of
                                        Nothing ->
                                            Text (RichText.Plain ([ "Error:", "'" ++ model.pwd ++ "'", "no such file or directory" ] |> String.join " "))
                                                |> List.singleton
                                                |> List.append model.output

                                        Just node ->
                                            Text (FS.list node)
                                                |> List.singleton
                                                |> List.append model.output
                    in
                    ( { model | output = output }, Cmd.none )
            }
          )
        , ( "tree"
          , { name = "tree"
            , arguments = "[FILE]"
            , description = "list contents of directories in a tree-like format"
            , minArgs = 0
            , maxArgs = Just 1
            , run =
                \args model ->
                    let
                        output =
                            case args of
                                [] ->
                                    case FS.resolvePath model.pwd fileSystem of
                                        Nothing ->
                                            Text (RichText.Line (RichText.Plain ([ "Error: the directory", "'" ++ model.pwd ++ "'", "does not exist" ] |> String.join " ")))
                                                |> List.singleton
                                                |> List.append model.output

                                        Just node ->
                                            FS.tree node
                                                |> Text
                                                |> List.singleton
                                                |> List.append model.output

                                path :: _ ->
                                    case FS.resolvePath (model.pwd ++ "/" ++ path) fileSystem of
                                        Nothing ->
                                            Text (RichText.Line (RichText.Plain ([ "Error: the directory", "'" ++ path ++ "'", "does not exist" ] |> String.join " ")))
                                                |> List.singleton
                                                |> List.append model.output

                                        Just node ->
                                            case node of
                                                FS.File _ _ ->
                                                    Text (RichText.Line (RichText.Plain ([ "Error:", "'" ++ path ++ "'", "is not a directory" ] |> String.join " ")))
                                                        |> List.singleton
                                                        |> List.append model.output

                                                FS.Directory _ _ ->
                                                    FS.tree node
                                                        |> Text
                                                        |> List.singleton
                                                        |> List.append model.output
                    in
                    ( { model | output = output }, Cmd.none )
            }
          )
        , ( "cat"
          , { name = "cat"
            , arguments = "FILE..."
            , description = "concatenate files and output them"
            , minArgs = 0
            , maxArgs = Nothing
            , run =
                \args model ->
                    let
                        output =
                            args
                                |> List.map
                                    (\path ->
                                        case FS.resolvePath (model.pwd ++ "/" ++ path) fileSystem of
                                            Nothing ->
                                                Text (RichText.Line (RichText.Plain ([ "Error: file", "'" ++ path ++ "'", "does not exist" ] |> String.join " ")))

                                            Just node ->
                                                case node of
                                                    FS.File _ content ->
                                                        content |> Text

                                                    FS.Directory _ _ ->
                                                        Text (RichText.Line (RichText.Plain ([ "Error:", "'" ++ path ++ "'", "is a directory" ] |> String.join " ")))
                                    )
                                |> List.append model.output
                    in
                    if List.isEmpty args then
                        ( model
                        , Http.get
                            { url = "https://api.thecatapi.com/v1/images/search"
                            , expect = Http.expectJson GotImage (Decode.index 0 (Decode.field "url" Decode.string))
                            }
                        )

                    else
                        ( { model | output = output }, Cmd.none )
            }
          )
        , ( "help"
          , { name = "help"
            , arguments = "[COMMAND]"
            , description = "display this help message"
            , minArgs = 0
            , maxArgs = Just 1
            , run =
                \args model ->
                    let
                        output =
                            case args of
                                [] ->
                                    let
                                        values =
                                            commands |> Dict.values |> List.sortBy (\cmd -> cmd.name)

                                        maxLen =
                                            values |> List.map (\cmd -> String.length cmd.name + String.length cmd.arguments + 1) |> List.maximum |> Maybe.withDefault 0
                                    in
                                    values
                                        |> List.map
                                            (\cmd ->
                                                Text
                                                    (RichText.Line
                                                        (RichText.Group
                                                            [ RichText.Styled [ RichText.Bold ] (RichText.Plain ([ cmd.name, cmd.arguments ] |> String.join " "))
                                                            , RichText.Plain (String.repeat (maxLen - (String.length cmd.name + String.length cmd.arguments + 1)) " " ++ "  " ++ cmd.description)
                                                            ]
                                                        )
                                                    )
                                            )
                                        |> List.append model.output

                                name :: _ ->
                                    case Dict.get name commands of
                                        Just cmd ->
                                            [ Text (RichText.Line (RichText.Plain cmd.description))
                                            , Text (RichText.Line (RichText.Plain ""))
                                            , Text (RichText.Line (RichText.Plain ([ "Usage:", cmd.name, cmd.arguments ] |> String.join " ")))
                                            ]
                                                |> List.append model.output

                                        Nothing ->
                                            Text (RichText.Line (RichText.Plain ([ "Error:", "'" ++ name ++ "'", "does not exist" ] |> String.join " ")))
                                                |> List.singleton
                                                |> List.append model.output
                    in
                    ( { model | output = output }, Cmd.none )
            }
          )
        ]


init : a -> ( Model, Cmd msg )
init _ =
    ( { input = ""
      , history = []
      , output = []
      , pwd = "/"
      }
    , Cmd.none
    )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch [ onKeyPressFocus ]


onKeyPressFocus : Sub Msg
onKeyPressFocus =
    onKeyPress <|
        Decode.map2
            (\ctrl meta ->
                if ctrl || meta then
                    NoOp

                else
                    FocusInput
            )
            (Decode.field "ctrlKey" Decode.bool)
            (Decode.field "metaKey" Decode.bool)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateInput newInput ->
            ( { model | input = newInput }
            , Cmd.none
            )

        Submit ->
            processCmd
                { model
                    | history = model.history ++ [ model.input ]
                    , output = model.output ++ [ Text (RichText.Line (RichText.Group [ prompt, RichText.Plain model.input ])) ]
                    , input = ""
                }
                (String.words model.input)
                |> (\( m, c ) -> ( m, Cmd.batch [ c, scrollToBottom ] ))

        FocusInput ->
            ( model, Dom.focus "shell-line-input" |> Task.attempt (always NoOp) )

        GotImage res ->
            res
                |> Result.map (\url -> ( { model | output = model.output ++ [ Image url ] }, scrollToBottom ))
                |> Result.withDefault ( model, Cmd.none )

        ScrollDone _ ->
            ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


scrollToBottom : Cmd Msg
scrollToBottom =
    Dom.setViewport 0.0 1.0e9 |> Task.attempt ScrollDone


processCmd : Model -> List String -> ( Model, Cmd Msg )
processCmd model argv =
    case argv of
        [] ->
            ( model, Cmd.none )

        name :: args ->
            case Dict.get name commands of
                Just cmd ->
                    let
                        argCount =
                            List.length args
                    in
                    if argCount < cmd.minArgs then
                        ( { model | output = model.output ++ [ Text (RichText.Line (RichText.Plain ([ "Error:", "'" ++ name ++ "'", "requires at least", String.fromInt cmd.minArgs, "argument(s)" ] |> String.join " "))) ] }, Cmd.none )

                    else
                        case cmd.maxArgs of
                            Just max ->
                                if argCount > max then
                                    ( { model | output = model.output ++ [ Text (RichText.Line (RichText.Plain ([ "Error:", "'" ++ name ++ "'", "requires at most", String.fromInt cmd.minArgs, "argument(s)" ] |> String.join " "))) ] }, Cmd.none )

                                else
                                    cmd.run args model

                            Nothing ->
                                cmd.run args model

                Nothing ->
                    if name == "" then
                        ( model, Cmd.none )

                    else
                        ( { model | output = model.output ++ [ Text (RichText.Line (RichText.Plain ("Unknown command: " ++ name))) ] }, Cmd.none )


view : Model -> Html Msg
view model =
    main_ []
        [ viewOutput model
        , viewInput model
        ]


viewOutput : Model -> Html Msg
viewOutput model =
    div [ class "output" ]
        (model.output
            |> List.concatMap
                (\o ->
                    case o of
                        Text rt ->
                            RichText.view rt

                        Image u ->
                            [ img [ src u ] [ text u ] ]
                )
        )


viewInput : Model -> Html Msg
viewInput model =
    div [ class "shell-line" ]
        [ div [ class "shell-line-prompt" ] (RichText.view prompt)
        , textarea [ id "shell-line-input", autofocus True, value model.input, onInput UpdateInput, onEnterSubmit ] []
        ]


onEnterSubmit : Attribute Msg
onEnterSubmit =
    preventDefaultOn "keydown" <|
        (Decode.field "key" Decode.string
            |> Decode.map
                (\key ->
                    if key == "Enter" then
                        ( Submit, True )

                    else
                        ( NoOp, False )
                )
        )
