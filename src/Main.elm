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


data : { about : RichText, contact : RichText, projects : List { name : RichText, description : RichText, repository : RichText, language : RichText } }
data =
    { about =
        RichText.Group
            [ RichText.Line (RichText.Plain "Hi, I'm Ahmed, a software developer interested in programming language theory, functional programming, systems programming, and graphics programming. I like computers, music and cats.")
            , RichText.Line (RichText.Plain "")
            , RichText.Line (RichText.Plain "I'm currently studying programming language theory and making https://github.com/amedoeyes/void-lang a statically typed functional language inspired by Haskell and Rust.")
            , RichText.Line (RichText.Plain "")
            , RichText.Line (RichText.Plain "I used to work on my own game engine https://github.com/amedoeyes/void-engine but I dropped it after exploring Rust and Bevy. The reason is that Bevy is everything I want in a game engine, and I realized that contributing to an established game engine is a better use of my time than rewriting my own engine from scratch for the 5th time (yes it was gonna be the 5th lmao).")
            , RichText.Line (RichText.Plain "")
            , RichText.Line (RichText.Plain "My setup is NixOS and Helix. You can check my dotfiles at https://github.com/amedoeyes/dotfiles")
            , RichText.Line (RichText.Plain "")
            , RichText.Line (RichText.Plain "Regarding music, I mostly listen to Maidcore, Shoegaze, and Progressive Metal. My favorite artists are Yakui The Maid, abriction, and Polyphia. I also practice guitar when I'm not programming.")
            , RichText.Line (RichText.Plain "")
            , RichText.Line (RichText.Plain "Lastly, I value humanity.")
            ]
    , contact =
        RichText.Group
            [ RichText.Line (RichText.Plain "Email: amedoeyes@gmail.com")
            , RichText.Line (RichText.Plain "Discord: @amedoeyes")
            , RichText.Line (RichText.Plain "Github: https://github.com/amedoeyes ")
            ]
    , projects =
        [ { name = RichText.Plain "void-lang"
          , description = RichText.Plain "Statically typed, lazily-evaluated functional programming language with Hindley-Milner type inference. Inspired by Haskell and Rust."
          , repository = RichText.Plain "https://github.com/amedoeyes/void-lang"
          , language = RichText.Plain "Rust"
          }
        , { name = RichText.Plain "mason"
          , description = RichText.Plain "Command-line tool to manage external development tools like LSP servers, debuggers, linters, and formatters."
          , repository = RichText.Plain "https://github.com/amedoeyes/mason"
          , language = RichText.Plain "Go"
          }
        , { name = RichText.Plain "mprisctl"
          , description = RichText.Plain "Command-line tool to interact with MPRIS compatible media players."
          , repository = RichText.Plain "https://github.com/amedoeyes/mprisctl"
          , language = RichText.Plain "Rust"
          }
        , { name = RichText.Plain "void-engine"
          , description = RichText.Plain "Cross platform C++23 game engine."
          , repository = RichText.Plain "https://github.com/amedoeyes/void-engine"
          , language = RichText.Plain "C++"
          }
        , { name = RichText.Plain "cli"
          , description = RichText.Plain "Simple modern C++23 command-line interface library."
          , repository = RichText.Plain "https://github.com/amedoeyes/cli"
          , language = RichText.Plain "C++"
          }
        , { name = RichText.Plain "lexer"
          , description = RichText.Plain "Modular modern C++23 lexer library."
          , repository = RichText.Plain "https://github.com/amedoeyes/lexer"
          , language = RichText.Plain "C++"
          }
        , { name = RichText.Plain "portofolio"
          , description = RichText.Plain "This protofolio."
          , repository = RichText.Plain "https://github.com/amedoeyes/amedoeyes.github.io"
          , language = RichText.Plain "Elm"
          }
        ]
    }


fileSystem : FS.Node
fileSystem =
    FS.Directory ""
        [ FS.File "about.txt" data.about
        , FS.File "contact.txt" data.contact
        , FS.File "projects.txt"
            (let
                maxLen =
                    data.projects |> List.map (\p -> RichText.length p.name) |> List.maximum |> Maybe.withDefault 0
             in
             data.projects
                |> List.map
                    (\p ->
                        RichText.Line
                            (RichText.Group
                                [ RichText.Styled [ RichText.Bold ] p.name
                                , RichText.Plain (String.repeat (maxLen - RichText.length p.name + 2) " ")
                                , p.description
                                ]
                            )
                    )
                |> RichText.Group
            )
        , FS.Directory "projects"
            (data.projects
                |> List.map
                    (\p ->
                        FS.File
                            (RichText.toString p.name ++ ".txt")
                            (RichText.Group
                                [ RichText.Line (RichText.Group [ RichText.Styled [ RichText.Color "#808080" ] (RichText.Plain "Name: "), p.name ])
                                , RichText.Line (RichText.Group [ RichText.Styled [ RichText.Color "#808080" ] (RichText.Plain "Description: "), p.description ])
                                , RichText.Line (RichText.Group [ RichText.Styled [ RichText.Color "#808080" ] (RichText.Plain "Repository: "), p.repository ])
                                , RichText.Line (RichText.Group [ RichText.Styled [ RichText.Color "#808080" ] (RichText.Plain "Language: "), p.language ])
                                ]
                            )
                    )
            )
        , FS.Reference "resume.pdf" "./ahmed_aboueleyoun_resume.pdf"
        ]


prompt : RichText
prompt =
    RichText.Styled [ RichText.Color "#606060" ] (RichText.Plain "$ ")


init : a -> ( Model, Cmd msg )
init _ =
    ( { input = ""
      , output = [ IO.Text (RichText.Line (RichText.Group [ RichText.Plain "type ", RichText.Styled [ RichText.Color "#808080" ] (RichText.Plain "help"), RichText.Plain " to see all commands" ])) ]
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
