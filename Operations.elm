module Operations exposing (..)

import Html exposing
  ( Html, Attribute, text
  , h1, h2, div, textarea, button, p, a
  , table, tbody, thead, tr, th, td
  , input, select, option, header, nav
  , span, section, nav, img, label
  )
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit, onWithOptions)
import Json.Decode as J

import Asset exposing (..)
import Helpers exposing (..)

type OpData
  = CreateAccount Create
  | Payment Pay
  | PathPayment PathPay
  | ManageOfferOrPassive Offer
  | SetOptions SetOpt
  | ChangeTrust Trust
  | AllowTrust Allow
  | AccountMerge Merge
  | Inflation Infl
  | ManageData ManData
  | None

opDataDecoder : J.Decoder OpData
opDataDecoder =
  J.oneOf
    [ createDecoder
    , payDecoder
    , pathPayDecoder
    , offerDecoder
    , setOptDecoder
    , trustDecoder
    , allowDecoder
    , mergeDecoder
    , inflDecoder
    , manDataDecoder
    , J.null None
    ]

opDataRows : (String -> msg) -> OpData -> List (Html msg)
opDataRows nav data =
  case data of
    CreateAccount create ->
      [ tr []
        [ th [] [ text "funder" ]
        , td [] [ addrlink nav create.funder ]
        ]
      , tr []
        [ th [] [ text "starting_balance" ]
        , td [ class "emphasis" ] [ text create.starting_balance ]
        ]
      , tr []
        [ th [] [ text "account" ]
        , td [] [ addrlink nav create.account ]
        ]
      ]
    Payment pay ->
      [ tr []
        [ th [] [ text "amount" ]
        , td [ class "emphasis" ] [ text pay.amount ]
        ]
      , tr []
        [ th [] [ text "asset" ]
        , td [] [ viewAsset nav pay.asset ]
        ]
      , tr []
        [ th [] [ text "from" ]
        , td [] [ addrlink nav pay.from ]
        ]
      , tr []
        [ th [] [ text "to" ]
        , td [] [ addrlink nav pay.to ]
        ]
      ]
    PathPayment pathp ->
      [ tr []
        [ th [] [ text "amount" ]
        , td [ class "emphasis" ] [ text pathp.amount ]
        ]
      , tr []
        [ th [] [ text "asset" ]
        , td [] [ viewAsset nav pathp.asset ]
        ]
      , tr []
        [ th [] [ text "from" ]
        , td [] [ addrlink nav pathp.from ]
        ]
      , tr []
        [ th [] [ text "to" ]
        , td [] [ addrlink nav pathp.to ]
        ]
      , tr []
        [ th [] [ text "path" ]
        , td []
          <| List.intersperse (text " -> ")
          <| List.map (viewAsset nav) pathp.path
        ]
      ]
    ManageOfferOrPassive offer ->
      [ tr []
        [ th [] [ text "offer_id" ]
        , td [] [ text <| toString offer.offer_id ]
        ]
      , tr []
        [ th [] [ text "buying" ]
        , td [] [ viewAsset nav offer.buying ]
        ]
      , tr []
        [ th [] [ text "price" ]
        , td [ class "emphasis" ] [ text offer.price ]
        ]
      , tr []
        [ th [] [ text "selling" ]
        , td [] [ viewAsset nav offer.selling ]
        ]
      , tr []
        [ th [] [ text "amount" ]
        , td [] [ text offer.amount ]
        ]
      ]
    SetOptions so ->
      [ if so.inflation_dest == "" then text "" else tr []
        [ th [] [ text "inflation_dest" ]
        , td [] [ text so.inflation_dest ]
        ]
      , if so.home_domain == "" then text "" else tr []
        [ th [] [ text "home_domain" ]
        , td [] [ text so.home_domain ]
        ]
      , if so.signer_key == "" then text "" else tr []
        [ th [] [ text "signer_key" ]
        , td [] [ text so.signer_key ]
        ]
      , if so.signer_weight == -1 then text "" else tr []
        [ th [] [ text "signer_weight" ]
        , td [] [ text <| toString so.signer_weight ]
        ]
      , if so.master_key_weight == -1 then text "" else tr []
        [ th [] [ text "master_key_weight" ]
        , td [] [ text <| toString so.master_key_weight ]
        ]
      , if so.low_threshold == -1 then text "" else tr []
        [ th [] [ text "low_threshold" ]
        , td [] [ text <| toString so.low_threshold ]
        ]
      , if so.med_threshold == -1 then text "" else tr []
        [ th [] [ text "med_threshold" ]
        , td [] [ text <| toString so.med_threshold ]
        ]
      , if so.high_threshold == -1 then text "" else tr []
        [ th [] [ text "high_threshold" ]
        , td [] [ text <| toString so.high_threshold ]
        ]
      ]
    ChangeTrust trust ->
      [ tr []
        [ th [] [ text "trustor" ]
        , td [] [ addrlink nav trust.trustor ]
        ]
      , tr []
        [ th [] [ text "asset" ]
        , td [] [ viewAsset nav trust.asset ]
        ]
      , tr []
        [ th [] [ text "limit" ]
        , td [ class "emphasis" ] [ text trust.limit ]
        ]
      ]
    AllowTrust allow ->
      [ tr []
        [ th [] [ text "trustor" ]
        , td [] [ addrlink nav allow.trustor ]
        ]
      , tr []
        [ th [] [ text "authorize" ]
        , td [] [ text <| if allow.authorize then "yes" else "no" ]
        ]
      , tr []
        [ th [] [ text "asset" ]
        , td [] [ viewAsset nav allow.asset ]
        ]
      , tr []
        [ th [] [ text "limit" ]
        , td [ class "emphasis" ] [ text allow.limit ]
        ]
      ]
    AccountMerge merge ->
      [ tr []
        [ th [] [ text "account" ]
        , td [] [ addrlink nav merge.account ]
        ]
      , tr []
        [ th [] [ text "into" ]
        , td [] [ addrlink nav merge.into ]
        ]
      ]
    Inflation infl -> []
    ManageData md ->
      [ tr []
        [ th [] [ text "name" ]
        , td [] [ text md.name ]
        ]
      , tr []
        [ th [] [ text "value" ]
        , td [] [ text md.value ]
        ]
      ]
    None -> []


type alias Create =
  { funder : String
  , starting_balance : String
  , account : String
  }

createDecoder : J.Decoder OpData
createDecoder =
  J.map CreateAccount <| J.map3 Create
    ( J.field "funder" J.string )
    ( J.field "starting_balance" J.string )
    ( J.field "account" J.string )


type alias Pay =
  { asset : Asset
  , from : String
  , to : String
  , amount : String
  }

payDecoder : J.Decoder OpData
payDecoder =
  J.map Payment <| J.map4 Pay
    ( assetDecoder )
    ( J.field "from" J.string )
    ( J.field "to" J.string )
    ( J.field "amount" J.string )


type alias PathPay =
  { asset : Asset
  , from : String
  , to : String
  , amount : String
  , path : List Asset
  }

pathPayDecoder : J.Decoder OpData
pathPayDecoder =
  J.map PathPayment <| J.map5 PathPay
    ( assetDecoder )
    ( J.field "from" J.string )
    ( J.field "to" J.string )
    ( J.field "amount" J.string )
    ( J.field "path" <| J.list assetDecoder )


type alias Offer =
  { offer_id : Int
  , amount : String
  , price : String
  , buying : Asset
  , selling : Asset
  }

offerDecoder : J.Decoder OpData
offerDecoder =
  J.map ManageOfferOrPassive <| J.map5 Offer
    ( J.field "offer_id" J.int )
    ( J.field "amount" J.string )
    ( J.field "price" J.string )
    ( J.field "buying"
      <| J.map3 Asset
        ( J.field "buying_asset_type" J.string |> J.map ((==) "native") )
        ( J.field "buying_asset_code" J.string )
        ( J.field "buying_asset_issuer" J.string )
    )
    ( J.field "selling"
      <| J.map3 Asset
        ( J.field "selling_asset_type" J.string |> J.map ((==) "native") )
        ( J.field "selling_asset_code" J.string )
        ( J.field "selling_asset_issuer" J.string )
    )


type alias SetOpt =
  { inflation_dest : String
  , home_domain : String
  , signer_key : String
  , signer_weight : Int
  , master_key_weight : Int
  , low_threshold : Int
  , med_threshold : Int
  , high_threshold : Int
  }

setOptDecoder : J.Decoder OpData
setOptDecoder =
  J.map SetOptions <| J.map8 SetOpt
    ( J.map (Maybe.withDefault "") <| J.maybe ( J.field "inflation_dest" J.string ))
    ( J.map (Maybe.withDefault "") <| J.maybe ( J.field "home_domain" J.string ))
    ( J.map (Maybe.withDefault "") <| J.maybe ( J.field "signer_key" J.string ))
    ( J.map (Maybe.withDefault -1) <| J.maybe ( J.field "signer_weight" J.int ))
    ( J.map (Maybe.withDefault -1) <| J.maybe ( J.field "master_key_weight" J.int ))
    ( J.map (Maybe.withDefault -1) <| J.maybe ( J.field "low_threshold" J.int ))
    ( J.map (Maybe.withDefault -1) <| J.maybe ( J.field "med_threshold" J.int ))
    ( J.map (Maybe.withDefault -1) <| J.maybe ( J.field "high_threshold" J.int ))


type alias Trust =
  { asset : Asset
  , limit : String
  , trustee : String
  , trustor : String
  }

trustDecoder : J.Decoder OpData
trustDecoder =
  J.map ChangeTrust <| J.map4 Trust
    ( assetDecoder )
    ( J.field "limit" J.string )
    ( J.field "trustee" J.string )
    ( J.field "trustor" J.string )


type alias Allow =
  { asset : Asset
  , limit : String
  , trustee : String
  , trustor : String
  , authorize : Bool
  }

allowDecoder : J.Decoder OpData
allowDecoder =
  J.map AllowTrust <| J.map5 Allow
    ( assetDecoder )
    ( J.field "limit" J.string )
    ( J.field "trustee" J.string )
    ( J.field "trustor" J.string )
    ( J.field "authorize" J.bool )


type alias Merge =
  { account : String
  , into : String
  }

mergeDecoder : J.Decoder OpData
mergeDecoder =
  J.map AccountMerge <| J.map2 Merge
    ( J.field "account" J.string )
    ( J.field "into" J.string )


type alias Infl = {}

inflDecoder : J.Decoder OpData
inflDecoder =
  J.map Inflation <| J.null Infl


type alias ManData =
  { name : String
  , value : String
  }

manDataDecoder : J.Decoder OpData
manDataDecoder =
  J.map ManageData <| J.map2 ManData
    ( J.field "name" J.string )
    ( J.field "value" J.string )
