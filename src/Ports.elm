port module Ports exposing (download, downloadUrl, open, openUrl)


port open : { content : String, mimeType : String } -> Cmd msg


port download : { name : String, content : String, mimeType : String } -> Cmd msg


port openUrl : String -> Cmd msg


port downloadUrl : { name : String, url : String } -> Cmd msg
