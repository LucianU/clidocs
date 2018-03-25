module Main exposing (..)

import Dom.Scroll exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json
import Task exposing (Task)


---- MODEL ----


type alias Model =
    { command : String
    , history : List String
    }


type alias Entry =
    { annotation : String
    , comment :
        { description : String
        , example : String
        }
    }


init : ( Model, Cmd Msg )
init =
    ( { command = "", history = [] }, Cmd.none )


entry : Entry
entry =
    { annotation = "unzip : List (a, b) -> (List a, List b)"
    , comment =
        { description = "Decompose a list of tuples into a tuple of lists."
        , example = "unzip [(0, True), (17, False), (1337, True)] == ([0,17,1337], [True,False,True]) "
        }
    }



---- UPDATE ----


type Msg
    = NoOp
    | Input String
    | Submit


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        Input content ->
            ( { model | command = content }, Cmd.none )

        Submit ->
            ( { model | history = List.append model.history [ model.command ], command = "" }
            , Task.attempt (always NoOp) <| toBottom "history"
            )



---- VIEW ----


prompt : String
prompt =
    "docs> "


view : Model -> Html Msg
view model =
    div []
        [ div [ (id "history") ] <|
            List.map historyView model.history
        , label [ class "input" ]
            [ text prompt
            , input
                [ onEnter Submit
                , onInput Input
                , value model.command
                , autofocus True
                ]
                []
            ]
        ]


historyView : String -> Html Msg
historyView item =
    div []
        [ p []
            [ text (prompt ++ item)
            ]
        , entryView entry
        ]


entryView : Entry -> Html Msg
entryView item =
    div [ class "docs-entry" ]
        [ div [ class "docs-annotation" ]
            [ span []
                [ text item.annotation
                ]
            ]
        , div [ class "docs-comment" ]
            [ p [] [ text item.comment.description ]
            , pre []
                [ code []
                    [ text item.comment.example ]
                ]
            ]
        ]


onEnter : Msg -> Attribute Msg
onEnter msg =
    let
        isEnter code =
            if code == 13 then
                Json.succeed msg
            else
                Json.fail "not ENTER"
    in
        on "keydown" (Json.andThen isEnter keyCode)



---- PROGRAM ----


main : Program Never Model Msg
main =
    Html.program
        { view = view
        , init = init
        , update = update
        , subscriptions = always Sub.none
        }
