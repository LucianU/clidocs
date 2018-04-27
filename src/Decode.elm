module Decode exposing (..)

import Json.Decode exposing (..)


type alias Package =
    { name : String
    , modules : List Module
    }


type alias Module =
    { name : String
    , comment : String
    , aliases : List Alias
    , types : List Type
    , values : List Value
    }


type alias Alias =
    { name : String
    , comment : String
    , args : List String
    , type_ : String
    }


type alias Type =
    { name : String
    , comment : String
    , args : List String
    , cases : List (String, List String)
    }


type alias Value =
    { name : String
    , comment : String
    , type_ : String}


caseDecoder =
    map2 (,)
        (index 0 string)
        (index 1 (list string))


aliasDecoder =
    map4 Alias
        (field "name" string)
        (field "comment" string)
        (field "args" (list string))
        (field "type" string)


typeDecoder =
    map4 Type
        (field "name" string)
        (field "comment" string)
        (field "args" (list string))
        (field "cases" (list caseDecoder))


valueDecoder =
    map3 Value
        (field "name" string)
        (field "comment" string)
        (field "type" string)


moduleDecoder =
    map5 Module
        (field "name" string)
        (field "comment" string)
        (field "aliases" (list aliasDecoder))
        (field "types" (list typeDecoder))
        (field "values" (list valueDecoder))


packageDecoder =
    map2 Package
        (field "name" string)
        (field "modules" (list moduleDecoder))


responseDecoder =
    list packageDecoder
