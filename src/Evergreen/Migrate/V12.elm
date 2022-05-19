module Evergreen.Migrate.V12 exposing (..)

import Evergreen.V11.Types as Old
import Evergreen.V12.Types as New
import Lamdera.Migrations exposing (..)


frontendModel : Old.FrontendModel -> ModelMigration New.FrontendModel New.FrontendMsg
frontendModel old =
    ModelMigrated
        ( { problem = old.problem
          , solvedProblems = old.solvedProblems
          , clientId = old.clientId
          , loggedIn = old.loggedIn
          , progress =
                { addSub = Nothing
                , mul = Nothing
                , sqrt = Nothing
                , exponent = Nothing
                , score = 0
                }
          , navigation = old.navigation
          , leaderboard = []
          }
        , Cmd.none
        )


backendModel : Old.BackendModel -> ModelMigration New.BackendModel New.BackendMsg
backendModel old =
    ModelUnchanged


frontendMsg : Old.FrontendMsg -> MsgMigration New.FrontendMsg New.FrontendMsg
frontendMsg old =
    MsgOldValueIgnored


toBackend : Old.ToBackend -> MsgMigration New.ToBackend New.BackendMsg
toBackend old =
    MsgUnchanged


backendMsg : Old.BackendMsg -> MsgMigration New.BackendMsg New.BackendMsg
backendMsg old =
    MsgUnchanged


toFrontend : Old.ToFrontend -> MsgMigration New.ToFrontend New.FrontendMsg
toFrontend old =
    MsgOldValueIgnored
