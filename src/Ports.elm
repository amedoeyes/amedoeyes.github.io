port module Ports exposing (download, open)


port download : { name : String, content : String, mimeType : String } -> Cmd msg


port open : { content : String, mimeType : String } -> Cmd msg


port openUrl : String -> Cmd msg
