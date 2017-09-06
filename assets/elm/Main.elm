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

-- Challenge is to connect to channel - need to have a token.

-- Have Saved User With Token?> Try to join Data Channel
-- -- Successfully Connect. (WOOOHOOO)
-- -- Cannot Connect.  Remove Token go to Do not have token.

-- Do not have Token. Join Auth Channel
-- -- Do you have login details for existing user?
-- -- Yes. Use details to Get Token From Auth Channel
-- -- Not. Sign up to add user details and get user token details.


type alias Data =
  { user: User }

type alias User =
  { email: String, token:String }

type alias Model =
  { phxSocket : Phoenix.Socket.Socket Msg,
    user: Maybe User,
    loginEmail: String,
    loginPassword: String,
    connected: Bool
  }

initPhxSocket : Phoenix.Socket.Socket Msg
initPhxSocket =
    Phoenix.Socket.init "ws://localhost:4000/socket/websocket"
        |> Phoenix.Socket.withDebug
        -- |> Phoenix.Socket.on "new:player" "room:lobby" ReceiveMessage


init : ( Model, Cmd Msg )
init =
    ( {
       user = Just (User "jay@email.com" "1234")
      ,phxSocket = initPhxSocket
      ,loginEmail = ""
      ,loginPassword = ""
      ,connected = False
      },
      Cmd.none
    )

-- userEncoder : String -> JE.Value
-- userEncoder username =
--     JE.object [ ( "name", JE.string username ), () ]

userEncoder : User -> JE.Value
userEncoder user =
    let
        attributes =
            [ ( "email", JE.string user.email )
            , ( "token", JE.string user.token )
            ]
    in
        JE.object attributes

dataDecoder : JD.Decoder Data
dataDecoder =
  decode Data
    |> Json.Decode.Pipeline.required "user" userDecoder



userDecoder : JD.Decoder User
userDecoder =
    decode User
        |> Json.Decode.Pipeline.required "email" JD.string
        |> Json.Decode.Pipeline.required "token" JD.string



-- MESSAGES


type Msg =
    PhoenixMsg (Phoenix.Socket.Msg Msg)
    | JoinAuthChannel
    | JoinDataChannel
    | ShowJoinedDataMessage String
    | ShowLeftDataMessage String
    | ReceiveMessage JE.Value
    | ShowJoinDataErrorMessage String
    | NoOp



-- VIEW

enterView : Model -> Html Msg
enterView model =
  div [][
          button [ onClick JoinDataChannel ] [ text "Enter" ]
        ]
      -- [ input [ placeholder "Username", onInput Change ] []
      -- , input [ placeholder "Password", onInput Change ] []
      -- , button [ onClick JoinChannel ] [ text "Enter" ]
      -- ]

channelView: Model -> Html Msg
channelView model =
  div []
      [ text "Success" ]



view : Model -> Html Msg
view model =
  case model.connected of
    False ->
      enterView model
    True ->
      channelView model




-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )
        PhoenixMsg msg ->
            let
              ( phxSocket, phxCmd ) = Phoenix.Socket.update msg model.phxSocket
            in
              ( { model | phxSocket = phxSocket }
              , Cmd.map PhoenixMsg phxCmd
              )
        JoinDataChannel->
            case model.user of
              Just user ->
                let
                    _ = Debug.log "UPDATE" "Trying to join data channel"
                    channel =
                        Phoenix.Channel.init "room:lobby"
                            |> Phoenix.Channel.withPayload(userEncoder user)
                            |> Phoenix.Channel.onJoin (always (ShowJoinedDataMessage "room:lobby"))
                            |> Phoenix.Channel.onClose (always (ShowLeftDataMessage "room:lobby"))
                            |> Phoenix.Channel.onJoinError (always (ShowJoinDataErrorMessage "room:lobby"))


                    ( phxSocket, phxCmd ) =
                        Phoenix.Socket.join channel model.phxSocket
                in
                    ( { model | phxSocket = phxSocket }
                    , Cmd.map PhoenixMsg phxCmd
                    )
              Nothing ->
                ( model, Cmd.none )
        ShowJoinedDataMessage channelName ->
          ( {model | connected = True}, Cmd.none )
        ShowJoinDataErrorMessage channelName ->
          let
              _ = Debug.log "JOIN ERROR MESSAGE" channelName
          in
            ( model, Cmd.none)
        ShowLeftDataMessage channelName ->
          ( model, Cmd.none)
        JoinAuthChannel ->
          ( model, Cmd.none)
        ReceiveMessage message ->
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
