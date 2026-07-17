module Main exposing (..)

import Browser
import Browser.Dom as Dom
import Browser.Events exposing (onKeyPress)
import Dict exposing (Dict)
import FS
import Html exposing (Attribute, Html, div, img, main_, span, text, textarea)
import Html.Attributes exposing (autofocus, class, id, src, style, value)
import Html.Events exposing (onInput, preventDefaultOn)
import Http
import Json.Decode as Decode
import RichText exposing (..)
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
    = UpdatePrompt String
    | Submit
    | GotImage (Result Http.Error String)
    | ScrollDone (Result Dom.Error ())
    | FocusPrompt
    | NoOp


type alias Model =
    { prompt : String
    , history : List String
    , output : List Output
    , pwd : String
    }


type Output
    = Text (List Text)
    | Image String


type alias Command =
    { name : String
    , arguments : String
    , description : String
    , minArgs : Int
    , maxArgs : Maybe Int
    , run : List String -> Model -> ( Model, Cmd Msg )
    }


prompt : String
prompt =
    "$ "


fileSystem : FS.Node
fileSystem =
    FS.Directory ""
        [ FS.File "hello.txt" [ [ Plain "Hello world!" ] ]
        , FS.File "hello_lines.txt" [ [ Plain "Hello" ], [ Plain "world!" ] ]
        , FS.File "file1.txt" [ [ Plain "file 1" ] ]
        , FS.File "file2.txt" [ [ Plain "file 2" ] ]
        , FS.Directory "dir"
            [ FS.File "file1.txt" [ [ Plain "file 1" ] ]
            , FS.File "file2.txt" [ [ Plain "file 2" ] ]
            , FS.Directory "subdir"
                [ FS.File "file1.txt" [ [ Plain "file 1" ] ]
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
                    ( { model | output = model.output ++ [ Text (args |> List.map (\a -> Plain a)) ] }
                    , Cmd.none
                    )
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
                            [ Text [ Plain model.pwd ] ]
                    in
                    ( { model | output = model.output ++ output }, Cmd.none )
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
                                            ( model.pwd, model.output ++ [ Text [ Plain ("Error: '" ++ path ++ "' no such file or directory") ] ] )

                                        Just node ->
                                            case node of
                                                FS.File _ _ ->
                                                    ( model.pwd, model.output ++ [ Text [ Plain ("Error: '" ++ path ++ "' is not a directory") ] ] )

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
                                            [ Text [ Plain ("Error: '" ++ model.pwd ++ "' no such file or directory") ] ]

                                        Just node ->
                                            [ Text (FS.list node) ]

                                path :: _ ->
                                    case FS.resolvePath (model.pwd ++ "/" ++ path) fileSystem of
                                        Nothing ->
                                            [ Text [ Plain ("Error: '" ++ path ++ "' no such file or directory") ] ]

                                        Just node ->
                                            [ Text (FS.list node) ]
                    in
                    ( { model | output = model.output ++ output }, Cmd.none )
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
                                            [ Text [ Plain ("Error: '" ++ model.pwd ++ "' no such file or directory") ] ]

                                        Just node ->
                                            FS.tree node |> List.map (List.singleton >> Text)

                                path :: _ ->
                                    case FS.resolvePath (model.pwd ++ "/" ++ path) fileSystem of
                                        Nothing ->
                                            [ Text [ Plain ("Error: '" ++ path ++ "' no such file or directory") ] ]

                                        Just node ->
                                            FS.tree node |> List.map (List.singleton >> Text)
                    in
                    ( { model | output = model.output ++ output }, Cmd.none )
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
                                |> List.concatMap
                                    (\path ->
                                        case FS.resolvePath (model.pwd ++ "/" ++ path) fileSystem of
                                            Nothing ->
                                                [ Text [ Plain ("Error: '" ++ path ++ "' no such file or directory") ] ]

                                            Just node ->
                                                case node of
                                                    FS.File _ content ->
                                                        content |> List.map Text

                                                    FS.Directory _ _ ->
                                                        [ Text [ Plain ("Error: '" ++ path ++ "' is a directory") ] ]
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
                    ( { model
                        | output =
                            model.output
                                ++ (case args of
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
                                                            [ Styled ([ cmd.name, cmd.arguments ] |> String.join " ") [ Bold ]
                                                            , Plain (String.repeat (maxLen - (String.length cmd.name + String.length cmd.arguments + 1)) " " ++ "  " ++ cmd.description)
                                                            ]
                                                    )

                                        name :: _ ->
                                            case Dict.get name commands of
                                                Just cmd ->
                                                    [ Text [ Plain cmd.description ], Text [], Text [ Plain ([ "Usage:", cmd.name, cmd.arguments ] |> String.join " ") ] ]

                                                Nothing ->
                                                    [ Text [ Plain ([ "Error:", "'" ++ name ++ "'", "does not exist" ] |> String.join " ") ] ]
                                   )
                      }
                    , Cmd.none
                    )
            }
          )
        ]


init : a -> ( Model, Cmd msg )
init _ =
    ( { prompt = ""
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
                    FocusPrompt
            )
            (Decode.field "ctrlKey" Decode.bool)
            (Decode.field "metaKey" Decode.bool)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdatePrompt newPrompt ->
            ( { model | prompt = newPrompt }
            , Cmd.none
            )

        Submit ->
            let
                ( newModel, newCmd ) =
                    processCmd
                        { model
                            | history = model.history ++ [ model.prompt ]
                            , output = model.output ++ [ Text [ Styled prompt [ Color "#606060" ], Plain model.prompt ] ]
                            , prompt = ""
                        }
                        (String.words model.prompt)
            in
            ( newModel
            , Cmd.batch
                [ newCmd, scrollToBottom ]
            )

        FocusPrompt ->
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
                        ( { model | output = model.output ++ [ Text [ Plain ("Error: " ++ name ++ " requires at least " ++ String.fromInt cmd.minArgs ++ " argument(s)") ] ] }
                        , Cmd.none
                        )

                    else
                        case cmd.maxArgs of
                            Just max ->
                                if argCount > max then
                                    ( { model | output = model.output ++ [ Text [ Plain ("Error: " ++ name ++ " accepts at most " ++ String.fromInt max ++ " argument(s)") ] ] }
                                    , Cmd.none
                                    )

                                else
                                    cmd.run args model

                            Nothing ->
                                cmd.run args model

                Nothing ->
                    if name == "" then
                        ( model, Cmd.none )

                    else
                        ( { model | output = model.output ++ [ Text [ Plain ("Unknown command: " ++ name) ] ] }
                        , Cmd.none
                        )


view : Model -> Html Msg
view model =
    main_ []
        [ viewOutput model
        , viewPrompt model
        ]


viewPrompt : Model -> Html Msg
viewPrompt model =
    div [ class "shell-line" ]
        [ div [ class "shell-line-prompt" ] [ viewText (Styled prompt [ Color "#606060" ]) ]
        , textarea [ id "shell-line-input", autofocus True, value model.prompt, onInput UpdatePrompt, onEnterSubmit ] []
        ]


viewText : Text -> Html Msg
viewText txt =
    case txt of
        Plain str ->
            text str

        Styled str styles ->
            span
                (styles
                    |> List.map
                        (\s ->
                            case s of
                                Color c ->
                                    style "color" c

                                Bold ->
                                    style "font-weight" "bold"
                        )
                )
                [ text str ]


viewOutput : Model -> Html Msg
viewOutput model =
    div [ class "output" ]
        (model.output
            |> List.map
                (\o ->
                    case o of
                        Text ts ->
                            div [] (ts |> List.map viewText)

                        Image u ->
                            img [ src u ] [ text u ]
                )
        )


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
