module Main exposing (..)

import Browser
import Browser.Dom as Dom
import Browser.Events exposing (onKeyPress)
import Commands exposing (Command)
import Dict exposing (Dict)
import FS
import Html exposing (Html, main_)
import Html.Events exposing (onInput, preventDefaultOn)
import IO
import Json.Decode as Decode
import RichText exposing (RichText)
import Task


type Msg
    = UpdateInput String
    | ProcessInput
    | FocusInput
    | GotImage String
    | NoOp


type alias Model =
    { input : String
    , output : List IO.Output
    , pwd : String
    , history : List String
    }


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , subscriptions = subscriptions
        , view = view
        , update = update
        }


commands : Dict String (Command Model Msg)
commands =
    Dict.fromList
        [ ( "echo", Commands.echo )
        , ( "clear", Commands.clear )
        , ( "pwd", Commands.pwd )
        , ( "cd", Commands.cd fileSystem )
        , ( "ls", Commands.ls fileSystem )
        , ( "tree", Commands.tree fileSystem )
        , ( "cat", Commands.cat fileSystem GotImage )
        , ( "open", Commands.open fileSystem )
        , ( "download", Commands.download fileSystem )
        , ( "help", Commands.help )
        ]


fileSystem : FS.Node
fileSystem =
    FS.Directory ""
        [ FS.File "hello.txt" (RichText.Line (RichText.Plain "Hello world!"))
        , FS.File "hello_lines.txt" (RichText.Group [ RichText.Line (RichText.Plain "Hello"), RichText.Line (RichText.Plain "world!") ])
        , FS.Reference "resume.pdf" "./ahmed_aboueleyoun_resume.pdf"
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


prompt : RichText
prompt =
    RichText.Styled [ RichText.Color "#606060" ] (RichText.Plain "$ ")


init : a -> ( Model, Cmd msg )
init _ =
    ( { input = ""
      , output = []
      , pwd = "/"
      , history = []
      }
    , Cmd.none
    )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ onKeyPress <|
            Decode.map2
                (\ctrl meta ->
                    if ctrl || meta then
                        NoOp

                    else
                        FocusInput
                )
                (Decode.field "ctrlKey" Decode.bool)
                (Decode.field "metaKey" Decode.bool)
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateInput newInput ->
            ( { model | input = newInput }, Cmd.none )

        ProcessInput ->
            let
                model_ =
                    { model
                        | history = model.history ++ [ model.input ]
                        , output = model.output ++ [ IO.Text (RichText.Line (RichText.Group [ prompt, RichText.Plain model.input ])) ]
                        , input = ""
                    }
            in
            case String.words model.input of
                [] ->
                    ( model_, Cmd.none )

                name :: args ->
                    case commands |> Dict.get name of
                        Just cmd ->
                            cmd args model_ |> (\( m, c ) -> ( m, Cmd.batch [ c, scrollToBottom ] ))

                        Nothing ->
                            if name == "" then
                                ( model_, scrollToBottom )

                            else
                                ( { model_ | output = model.output ++ [ IO.Text (RichText.Line (RichText.Plain ("Unknown command: " ++ name))) ] }, scrollToBottom )

        FocusInput ->
            ( model, Dom.focus "shell-line-input" |> Task.attempt (always NoOp) )

        GotImage url ->
            ( { model | output = model.output ++ [ IO.Image url ] }, scrollToBottom )

        NoOp ->
            ( model, Cmd.none )


scrollToBottom : Cmd Msg
scrollToBottom =
    Dom.setViewport 0.0 1.0e9 |> Task.attempt (always NoOp)


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
                                ( ProcessInput, True )

                            else
                                ( NoOp, False )
                        )
                )
            )
            model
        ]
