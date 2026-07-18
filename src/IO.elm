module IO exposing (Input, Output(..), viewInput, viewOutput)

import Html exposing (Html, div, img, text, textarea)
import Html.Attributes exposing (autofocus, class, id, src, value)
import RichText


type alias Input =
    String


type Output
    = Text RichText.RichText
    | Image String


viewInput : RichText.RichText -> Html.Attribute msg -> Html.Attribute msg -> { a | input : Input } -> Html msg
viewInput prompt onInput onEnter model =
    div [ class "shell-line" ]
        [ div [ class "shell-line-prompt" ] (RichText.view prompt)
        , textarea [ id "shell-line-input", autofocus True, value model.input, onInput, onEnter ] []
        ]


viewOutput : { a | output : List Output } -> Html msg
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
