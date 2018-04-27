module Main exposing (..)

import Dom
import Dom.Scroll exposing (..)
import Html exposing (..)
import Http
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json
import Task exposing (Task)
import Utils.Code
import Data
import Decode


---- MODEL ----


type alias Model =
    { command : String
    , history : List Command
    , historyCounter : Maybe Int
    , docs : List Data.Package
    }


type alias Command =
    { input : String
    , output : Output
    }


type Output
    = Enumeration (List String)
    | Detail Data.Construct
    | Error String
    | Help
    | None


init : ( Model, Cmd Msg )
init =
    ( { command = ""
      , history = []
      , historyCounter = Nothing
      , docs = []
      }
    , getDocs
    )



---- UPDATE ----


type HistoryNavKey
    = Up
    | Down


type Msg
    = NoOp
    | Input String
    | Submit
    | HistoryNavMsg HistoryNavKey
    | Tab
    | Focus
    | GetDocs (Result Http.Error (List Decode.Package))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        Input content ->
            ( { model | command = content }, Cmd.none )

        Tab ->
            ( model, Cmd.none )

        Submit ->
            let
                command =
                    { input = model.command
                    , output = parseCommand model
                    }
            in
                ( { model
                    | history = List.append model.history [ command ]
                    , historyCounter = Nothing
                    , command = ""
                  }
                , Task.attempt (always NoOp) <| toBottom "root"
                )

        HistoryNavMsg navKey ->
            cycleHistory model navKey

        Focus ->
            ( model, Task.attempt (always NoOp) <| Dom.focus "cmd" )

        GetDocs (Ok docs) ->
            ( { model | docs = Data.convertDocs docs }, Cmd.none )

        GetDocs (Err _) ->
            ( model, Cmd.none )


cycleHistory : Model -> HistoryNavKey -> ( Model, Cmd msg )
cycleHistory model navKey =
    let
        validHistory =
            List.filter (\command -> command.input /= "") model.history
    in
        if List.length validHistory == 0 then
            ( model, Cmd.none )
        else
            let
                historyCounter =
                    case model.historyCounter of
                        Just counter ->
                            counter

                        Nothing ->
                            List.length validHistory + 1
            in
                case navKey of
                    Up ->
                        if historyCounter == 0 then
                            ( model, Cmd.none )
                        else
                            setCommand model (historyCounter - 1) validHistory

                    Down ->
                        if historyCounter == List.length validHistory then
                            ( model, Cmd.none )
                        else
                            setCommand model (historyCounter + 1) validHistory


setCommand : Model -> Int -> List Command -> ( Model, Cmd msg )
setCommand model counter commands =
    let
        maybeCommand =
            List.head <| List.reverse <| List.take counter commands
    in
        case maybeCommand of
            Just command ->
                ( { model
                    | command = command.input
                    , historyCounter = Just counter
                  }
                , Cmd.none
                )

            Nothing ->
                ( model, Cmd.none )


getDocs : Cmd Msg
getDocs =
    let
        url =
            "http://localhost:3000/docs"

        request =
            Http.get url Decode.responseDecoder
    in
        Http.send GetDocs request


parseCommand : Model -> Output
parseCommand model =
    let
        command =
            model.command
    in
        if command == "" then
            None
        else if command == "help" then
            Help
        else if command == "packages" then
            Enumeration <| List.map (\package -> package.name) model.docs
        else if String.startsWith "modules" command then
            parseModulesCommand model command
        else if String.startsWith "docs" command then
            parseDocCommand model command
        else
            Error <| "Unknown command " ++ command


parseModulesCommand : Model -> String -> Output
parseModulesCommand model command =
    let
        components =
            String.split " " command
    in
        case components of
            [] ->
                Error <| "Missing command"

            [ cmd ] ->
                Error <| "You need to specify a package"

            cmd :: packageName :: _ ->
                let
                    package =
                        search packageName model.docs
                in
                    case package of
                        Just pack ->
                            Enumeration <| List.map (\mod -> mod.name) pack.modules

                        Nothing ->
                            Error <| "Unknown package " ++ packageName


parseDocCommand : Model -> String -> Output
parseDocCommand model command =
    let
        components =
            String.split " " command
    in
        case components of
            [] ->
                Error <| "Missing command"

            [ cmd ] ->
                Error <| "Missing argument to `docs`"

            cmd :: symbol :: _ ->
                let
                    symbolBits =
                        String.split "." symbol
                in
                    case symbolBits of
                        [] ->
                            Error <| "Missing argument to `docs`"

                        [ moduleName ] ->
                            case searchModule moduleName model.docs of
                                Just mod ->
                                    Enumeration <| listModuleTypes mod

                                Nothing ->
                                    Error <| "Unknown module " ++ moduleName

                        moduleName :: typeName :: _ ->
                            case searchModule moduleName model.docs of
                                Just mod ->
                                    case search typeName mod.types of
                                        Just type_ ->
                                            Detail type_

                                        Nothing ->
                                            Error <| "Unknown type " ++ typeName

                                Nothing ->
                                    Error <| "Unknown module " ++ moduleName


listModuleTypes : Data.Module -> List String
listModuleTypes mod =
    List.map (\type_ -> type_.name) mod.types


searchModule : String -> List Data.Package -> Maybe Data.Module
searchModule moduleName packages =
    case packages of
        [] ->
            Nothing

        package :: rest ->
            case moduleIn moduleName package.modules of
                Just mod ->
                    Just mod

                Nothing ->
                    searchModule moduleName rest


moduleIn : String -> List Data.Module -> Maybe Data.Module
moduleIn moduleName modules =
    case modules of
        [] ->
            Nothing

        mod :: rest ->
            if mod.name == moduleName then
                Just mod
            else
                moduleIn moduleName rest


search : String -> List { obj | name : String } -> Maybe { obj | name : String }
search objName objList =
    let
        hit =
            List.filter (\obj -> obj.name == objName) objList
    in
        List.head hit



---- VIEW ----


prompt : String
prompt =
    "elm> "


view : Model -> Html Msg
view model =
    div [ id "terminal", onClick Focus ]
        [ div [ id "history" ] <|
            List.map historyView model.history
        , label [ class "input" ]
            [ text prompt
            , input
                [ id "cmd"
                , type_ "text"
                , onKeyPress
                , onInput Input
                , value model.command
                , autofocus True
                ]
                []
            ]
        ]


promptView : String -> Html Msg
promptView commandStr =
    p []
        [ text <| prompt ++ commandStr ]


historyView : Command -> Html Msg
historyView command =
    case command.output of
        None ->
            div []
                [ promptView ""
                ]

        Enumeration members ->
            div []
                [ promptView command.input
                , enumerationView members
                ]

        Detail construct ->
            div []
                [ promptView command.input
                , constructView construct
                ]

        Error error ->
            div []
                [ promptView command.input
                , div [ class "error" ]
                    [ text error
                    ]
                ]

        Help ->
            div []
                [ promptView command.input
                , helpView
                ]


enumerationView : List String -> Html Msg
enumerationView members =
    let
        items =
            List.map (\item -> li [] [ text item ]) members
    in
        ul []
            items


constructView : Data.Construct -> Html Msg
constructView item =
    div [ class "docs-entry" ]
        [ div [ class "docs-annotation" ]
            [ span []
                [ Utils.Code.block ("    " ++ item.typeDef)
                ]
            ]
        , div [ class "docs-comment" ]
            [ Utils.Code.block item.comment
            ]
        ]


modView : Data.Module -> Html Msg
modView mod =
    div [ class "docs-entry" ]
        [ div [ class "docs-comment" ]
            [ Utils.Code.block mod.comment
            ]
        ]


helpView : Html Msg
helpView =
    div []
        [ span []
            [ text "Supported commands" ]
        , ul []
            [ li []
                [ text "help: shows this message"
                ]
            , li []
                [ text "packages: lists packages for which documentation is available"
                ]
            , li []
                [ Utils.Code.block """modules [package]: lists the modules in the package

    example: modules core"""
                ]
            , li []
                [ Utils.Code.block """docs [module|module.type]: shows the
                documentation for the specified item

    example:
        docs Array
        docs Array.empty""" ]
            ]
        ]


onKeyPress : Attribute Msg
onKeyPress =
    let
        isRelevantKey code =
            if code == 9 then
                Json.succeed Tab
            else if code == 13 then
                Json.succeed Submit
            else if code == 38 then
                Json.succeed (HistoryNavMsg Up)
            else if code == 40 then
                Json.succeed (HistoryNavMsg Down)
            else
                Json.fail "irrelevant key"
    in
        on "keydown" (Json.andThen isRelevantKey keyCode)



---- PROGRAM ----


main : Program Never Model Msg
main =
    Html.program
        { view = view
        , init = init
        , update = update
        , subscriptions = always Sub.none
        }
