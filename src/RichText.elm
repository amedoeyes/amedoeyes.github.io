module RichText exposing (RichText(..), Style(..), length, toString, view)

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


toString : RichText -> String
toString richText =
    case richText of
        Plain str ->
            str

        Styled _ rt ->
            toString rt

        Line rt ->
            toString rt ++ "\n"

        Group rts ->
            rts |> List.map toString |> String.concat


length : RichText -> Int
length richText =
    richText |> toString |> String.length


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
