module RichText exposing (Style(..), Text(..))


type Text
    = Plain String
    | Styled String (List Style)


type Style
    = Color String
    | Bold
