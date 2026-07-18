module RichText exposing (RichText(..), Style(..), view)

import Html exposing (Html, div, span, text)
import Html.Attributes exposing (style)


type RichText
    = Plain String
    | Styled (List Style) RichText
    | Line RichText
    | Group (List RichText)


type Style
    = Color String
    | Bold


view : RichText -> List (Html msg)
view richText =
    case richText of
        Plain str ->
            [ span [] [ text str ] ]

        Styled styles rt ->
            [ span
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
                (view rt)
            ]

        Line rt ->
            [ div [] (view rt) ]

        Group rts ->
            rts |> List.concatMap view
