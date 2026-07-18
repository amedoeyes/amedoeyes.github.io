module Main exposing (..)

import Browser
import Browser.Dom as Dom
import Browser.Events exposing (onKeyPress)
import Commands exposing (Command)
import Dict exposing (Dict)
import FS
import Html exposing (Attribute, Html, main_)
import Html.Events exposing (onInput, preventDefaultOn)
import Http
import IO
import Json.Decode as Decode
import RichText exposing (RichText)
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
    , output : List IO.Output
    , fileSystem : FS.Node
    , pwd : String
    }


commands : Dict String (Command Model Msg)
commands =
    Dict.fromList
        [ ( "echo", Commands.echo )
        , ( "clear", Commands.clear )
        , ( "pwd", Commands.pwd )
        , ( "cd", Commands.cd )
        , ( "ls", Commands.ls )
        , ( "tree", Commands.tree )
        , ( "cat", Commands.cat GotImage )
        , ( "help", Commands.help )
        ]


prompt : RichText
prompt =
    RichText.Styled [ RichText.Color "#606060" ] (RichText.Plain "$ ")


init : a -> ( Model, Cmd msg )
init _ =
    ( { input = ""
      , history = []
      , output = []
      , fileSystem =
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
            ( { model | input = newInput }, Cmd.none )

        Submit ->
            processCmd
                { model
                    | history = model.history ++ [ model.input ]
                    , output = model.output ++ [ IO.Text (RichText.Line (RichText.Group [ prompt, RichText.Plain model.input ])) ]
                    , input = ""
                }
                (String.words model.input)
                |> (\( m, c ) -> ( m, Cmd.batch [ c, scrollToBottom ] ))

        FocusInput ->
            ( model, Dom.focus "shell-line-input" |> Task.attempt (always NoOp) )

        GotImage res ->
            res
                |> Result.map (\url -> ( { model | output = model.output ++ [ IO.Image url ] }, scrollToBottom ))
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
            case commands |> Dict.get name of
                Just cmd ->
                    let
                        argCount =
                            List.length args
                    in
                    if argCount < cmd.minArgs then
                        ( { model | output = model.output ++ [ IO.Text (RichText.Line (RichText.Plain ([ "Error:", "'" ++ name ++ "'", "requires at least", String.fromInt cmd.minArgs, "argument(s)" ] |> String.join " "))) ] }, Cmd.none )

                    else
                        case cmd.maxArgs of
                            Just max ->
                                if argCount > max then
                                    ( { model | output = model.output ++ [ IO.Text (RichText.Line (RichText.Plain ([ "Error:", "'" ++ name ++ "'", "requires at most", String.fromInt cmd.minArgs, "argument(s)" ] |> String.join " "))) ] }, Cmd.none )

                                else
                                    cmd.run args model

                            Nothing ->
                                cmd.run args model

                Nothing ->
                    if name == "" then
                        ( model, Cmd.none )

                    else
                        ( { model | output = model.output ++ [ IO.Text (RichText.Line (RichText.Plain ("Unknown command: " ++ name))) ] }, Cmd.none )


view : Model -> Html Msg
view model =
    main_ []
        [ IO.viewOutput model
        , IO.viewInput prompt
            (onInput UpdateInput)
            (preventDefaultOn "keydown" <|
                (Decode.field "key" Decode.string
                    |> Decode.map
                        (\key ->
                            if key == "Enter" then
                                ( Submit, True )

                            else
                                ( NoOp, False )
                        )
                )
            )
            model
        ]
