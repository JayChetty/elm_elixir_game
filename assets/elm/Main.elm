module Main exposing (..)



import Html exposing (Html, Attribute, div, program, input, text, ul, li, button)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onSubmit, onClick)

import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push

import Debug

import Json.Encode as JE
import Json.Decode as JD exposing (field)
import Json.Decode.Pipeline exposing (decode, required)



  -- MODEL

type alias Position = {row: Int, col: Int}


type alias Data =
  { players: List Player }

type alias Player =
  { name: String }

type alias Model =
  { players: List Player,
    currentPlayerName: String,
    inGame: Bool,
    position: Position,
    phxSocket : Phoenix.Socket.Socket Msg,
    messages: List String
  }

initPhxSocket : Phoenix.Socket.Socket Msg
initPhxSocket =
    Phoenix.Socket.init "ws://localhost:4000/socket/websocket"
        |> Phoenix.Socket.withDebug
        |> Phoenix.Socket.on "new:player" "room:lobby" ReceiveMessage


init : ( Model, Cmd Msg )
init =
    ( {
       players = []
      ,currentPlayerName = ""
      ,inGame = False
      ,position = Position 0 0
      ,phxSocket = initPhxSocket
      ,messages = []
      },
      Cmd.none
    )



-- MESSAGES


type Msg=
    Change String
    | Submit
    | Move Position
    | PhoenixMsg (Phoenix.Socket.Msg Msg)
    | JoinChannel
    | ShowJoinedMessage String
    | ShowLeftMessage String
    | Ping
    | ReceiveMessage JE.Value
    | NoOp



-- VIEW

boardView : Model -> Html Msg
boardView model =
    div [class "board"]
      ( List.range 0 10
        |> List.map( boardRowView(model) )
      )


boardRowView : Model -> Int -> Html Msg
boardRowView model rowNum =
  div [class "row"]
    ( List.range 0 5
      |> List.map( boardCell(model)(rowNum)  )
    )

boardCell :  Model -> Int -> Int -> Html Msg
boardCell model rowNum colNum =
  case model.position.row == rowNum && model.position.col == colNum of
    True ->
      div([class "cell"])([ text "J"])
    False ->
      div [class "cell", onClick (Move (Position rowNum colNum)) ] []




enterView : Model -> Html Msg
enterView model =
  div []
      [ input [ placeholder "Player, enter name.", onInput Change ] []
      , button [ onClick JoinChannel ] [ text "Enter" ]
      ]


playersView : Model -> Html Msg
playersView model =
  div []
      [ul []
        ( List.map (\player -> li [] [ text player.name ]) model.players )
      ]

view : Model -> Html Msg
view model =
  let
    _ = Debug.log "VIEW" model
  in
  div []
    [
      enterView model
    , playersView model
    , button [ onClick Ping ] [ text "Ping" ]
    ]
  -- case model.inGame of
  --     True -> playView model
  --     False -> enterView model



userParams : String -> JE.Value
userParams username =
    JE.object [ ( "name", JE.string username ) ]

-- playersMessageDecoder : JD.Decoder (List Player)
-- playersMessageDecoder
--     JD
dataDecoder : JD.Decoder Data
dataDecoder =
  decode Data
    |> Json.Decode.Pipeline.required "players" playersDecoder

playersDecoder : JD.Decoder (List Player)
playersDecoder =
    JD.list playerDecoder


playerDecoder : JD.Decoder Player
playerDecoder =
    decode Player
        |> Json.Decode.Pipeline.required "name" JD.string

-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )
        Change text->
            ( { model | currentPlayerName = text }, Cmd.none )
        Move position ->
            ( { model | position = position }, Cmd.none )
        Submit->
            let
              newPlayer = { name = model.currentPlayerName }
              newPlayers = newPlayer :: model.players
            in
              ( { model | players = newPlayers, inGame = True }, Cmd.none )
        PhoenixMsg msg ->
            let
              ( phxSocket, phxCmd ) = Phoenix.Socket.update msg model.phxSocket
            in
              ( { model | phxSocket = phxSocket }
              , Cmd.map PhoenixMsg phxCmd
              )
        JoinChannel->
            let
                _ = Debug.log "UPDATE" "Trying to join channel"
                channel =
                    Phoenix.Channel.init "room:lobby"
                        |> Phoenix.Channel.withPayload(userParams model.currentPlayerName)
                        |> Phoenix.Channel.onJoin (always (ShowJoinedMessage "room:lobby"))
                        |> Phoenix.Channel.onClose (always (ShowLeftMessage "room:lobby"))

                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.join channel model.phxSocket
            in
                ( { model | phxSocket = phxSocket }
                , Cmd.map PhoenixMsg phxCmd
                )
        ShowJoinedMessage channelName ->
            let _ = Debug.log "UPDATE" "JOINED CHANNEL!"
            in
            ( { model |
                messages = ("Joined channel " ++ channelName) :: model.messages
              }
            , Cmd.none
            )

        ShowLeftMessage channelName ->
            ( { model | messages = ("Left channel " ++ channelName) :: model.messages }
            , Cmd.none
            )
        Ping ->
            let
                push_ =
                    Phoenix.Push.init "new_msg" "room:lobby"

                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.push push_ model.phxSocket
            in
                (  model , Cmd.map PhoenixMsg phxCmd )
        ReceiveMessage raw ->
            let
              _ = Debug.log "GOT A NEW MESSAGE" raw
            in
              case JD.decodeValue dataDecoder raw of
                Ok data->
                  let
                    _ = Debug.log "GOT Data" data
                  in
                  ({ model | players = data.players}, Cmd.none)
                Err error->
                  let
                    _ = Debug.log "ERROR MESSAGE" error
                  in
                  ( model, Cmd.none)






-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Phoenix.Socket.listen model.phxSocket PhoenixMsg


-- MAIN


main : Program Never Model Msg
main =
    program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
