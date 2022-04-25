module Evergreen.Migrate.V9 exposing (..)

import Dict
import Evergreen.V6.Types as Old
import Evergreen.V9.Types as New
import Lamdera.Migrations exposing (..)
import Problem exposing (emptyProblem)


frontendModel : Old.FrontendModel -> ModelMigration New.FrontendModel New.FrontendMsg
frontendModel old =
    ModelMigrated
        ( { problem = emptyProblem
          , solvedProblems = old.solvedProblems
          , clientId = old.clientId
          , loggedIn = False
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
        ( { progress = Dict.empty
          , sessionToProgressId = Dict.empty
          }
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
    MsgOldValueIgnored


toFrontend : Old.ToFrontend -> MsgMigration New.ToFrontend New.FrontendMsg
toFrontend _ =
    MsgOldValueIgnored
