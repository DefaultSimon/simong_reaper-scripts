-- @description Monitoring FX Bypass (based on FX names containing "[BYPASSABLE]")
-- @author Simon Goričar
-- @about
--   This package contains three scripts for bypassing, unbypassing and toggling monitor FX
--   based on their FX name (FX whose name contains "[BYPASSABLE]" are bypassed, 
--   unbypassed and toggled by these scripts).
-- @link https://github.com/DefaultSimon/simong_reaper-scripts
-- @version 1.0.6
-- @changelog
--   - Removed external dependency on the shared library - now included directly with this package instead.
-- @metapackage
-- @provides
--   [main=main] monitoring-fx-bypass/simong_Bypass all monitoring FX whose names contain BYPASSABLE.lua
--   [main=main] monitoring-fx-bypass/simong_Toggle bypass on all monitoring FX which names containing BYPASSABLE.lua
--   [main=main] monitoring-fx-bypass/simong_Unbypass all monitoring FX whose names contain BYPASSABLE.lua
--   [nomain]    monitoring-fx-bypass/simong_monitoring-fx-bypass-shared-library.lua