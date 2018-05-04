module Data exposing (Construct, Module, Package, convertDocs)

import Decode


type alias Construct =
    { name : String
    , typeDef : String
    , comment : String
    }


type alias Module =
    { name : String
    , comment : String
    , types : List Construct
    }


type alias Package =
    { name : String
    , modules : List Module
    }


convertDocs : List Decode.Package -> List Package
convertDocs docs =
    let
        getPackageName package =
            case String.split "/" package.name of
                [] ->
                    package.name

                [ name ] ->
                    package.name

                user :: packageName :: _ ->
                    packageName

        convert package =
            { name = getPackageName package
            , modules = convertModules (package.modules)
            }
    in
        List.map convert docs


convertModules : List Decode.Module -> List Module
convertModules modules =
    let
        convert mod =
            let
                types =
                    convertAliases (mod.aliases)
                        ++ convertTypes (mod.types)
                        ++ convertValues (mod.values)
            in
                { name = mod.name
                , comment = mod.comment
                , types = types
                }
    in
        List.map convert modules


convertTypeArgs : String -> List String -> String
convertTypeArgs type_ args =
    if List.length args == 0 then
        type_
    else
        type_ ++ " " ++ (String.join " " args)


convertAliases : List Decode.Alias -> List Construct
convertAliases aliases =
    let
        typeDef alias_ =
            let
                argsString =
                    convertTypeArgs (alias_.name) (alias_.args)
            in
                "type alias " ++ argsString ++ " = " ++ alias_.type_

        convert alias_ =
            { name = alias_.name
            , typeDef = typeDef alias_
            , comment = alias_.comment
            }
    in
        List.map convert aliases


convertCases : List ( String, List String ) -> List String
convertCases cases =
    let
        convert case_ =
            let
                ( tag, tagArgs ) =
                    case_
            in
                convertTypeArgs tag tagArgs
    in
        List.map convert cases


convertTypes : List Decode.Type -> List Construct
convertTypes types =
    let
        typeDef type_ =
            let
                argsString =
                    convertTypeArgs (type_.name) (type_.args)
            in
                if List.length (type_.cases) == 0 then
                    "type " ++ argsString
                else
                    "type "
                        ++ argsString
                        ++ "\n    = "
                        ++ (String.join "\n    | " <| convertCases <| type_.cases)

        convert type_ =
            { name = type_.name
            , typeDef = typeDef type_
            , comment = type_.comment
            }
    in
        List.map convert types


convertValues : List Decode.Value -> List Construct
convertValues values =
    let
        convert value =
            { name = value.name
            , typeDef = value.name ++ " : " ++ value.type_
            , comment = value.comment
            }
    in
        List.map convert values
