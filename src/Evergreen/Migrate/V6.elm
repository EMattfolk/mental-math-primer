module Evergreen.Migrate.V6 exposing (..)

import Dict
import Evergreen.V5.Types as Old
import Evergreen.V6.Types as New
import Lamdera.Migrations exposing (..)


frontendModel : Old.FrontendModel -> ModelMigration New.FrontendModel New.FrontendMsg
frontendModel old =
    ModelMigrated
        ( { problem = old.problem
          , solvedProblems = old.solvedProblems
          , clientId = old.clientId
          , progress =
                { addSub = Nothing
                , mul = Nothing
                }
          , navigation = old.navigation
          }
        , Cmd.none
        )


backendModel : Old.BackendModel -> ModelMigration New.BackendModel New.BackendMsg
backendModel _ =
    ModelMigrated
        ( Dict.empty
        , Cmd.none
        )


frontendMsg : Old.FrontendMsg -> MsgMigration New.FrontendMsg New.FrontendMsg
frontendMsg _ =
    MsgOldValueIgnored


toBackend : Old.ToBackend -> MsgMigration New.ToBackend New.BackendMsg
toBackend _ =
    MsgOldValueIgnored


backendMsg : Old.BackendMsg -> MsgMigration New.BackendMsg New.BackendMsg
backendMsg _ =
    MsgUnchanged


toFrontend : Old.ToFrontend -> MsgMigration New.ToFrontend New.FrontendMsg
toFrontend _ =
    MsgOldValueIgnored
