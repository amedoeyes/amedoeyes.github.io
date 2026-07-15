module Main exposing (..)

import Browser
import Browser.Dom as Dom
import Browser.Events exposing (onKeyPress)
import Dict exposing (Dict)
import Html exposing (Attribute, Html, div, img, main_, span, text, textarea)
import Html.Attributes exposing (alt, autofocus, class, id, src, style, value)
import Html.Events exposing (onInput, preventDefaultOn)
import Http
import Json.Decode as Decode
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
    }


type Output
    = Text (List Text)
    | Image String


type Text
    = Plain String
    | Styled String (List Style)


type Style
    = Color String
    | Bold


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
        , ( "cat"
          , { name = "cat"
            , arguments = ""
            , description = "cat!"
            , minArgs = 0
            , maxArgs = Nothing
            , run =
                \_ model ->
                    ( model
                    , Http.get
                        { url = "https://api.thecatapi.com/v1/images/search"
                        , expect = Http.expectJson GotImage (Decode.index 0 (Decode.field "url" Decode.string))
                        }
                    )
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
        , textarea [ id "shell-line-input", autofocus True, value model.prompt, onInput UpdatePrompt, onEnter Submit ] []
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
                            img [ src u, alt "Cat!" ] [ text u ]
                )
        )


onEnter : msg -> Attribute msg
onEnter msg =
    preventDefaultOn "keydown"
        (Decode.field "key" Decode.string
            |> Decode.andThen
                (\key ->
                    if key == "Enter" then
                        Decode.succeed ( msg, True )

                    else
                        Decode.fail "Not Enter"
                )
        )
