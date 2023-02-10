<h1 align="center">
    Simon Goričar's <a href="https://www.reaper.fm/">Reaper</a> Scripts
</h1>

## 1. Installation
Installation can be done via [ReaPack](https://reapack.com) by adding the following 
repository URL: 
```
https://github.com/DefaultSimon/simong_reaper-scripts/raw/master/index.xml
```

## 2. Contents

### 2.1. `Monitoring FX Bypass scripts (based on FX names containing "[BYPASSABLE]")`
> Requires the `Shared library for common functionality in the simong_reaper-scripts repository` package (install manually through the ReaPack browser).

This package contains the following three actions:
- `Bypass all monitoring FX whose names contain "[BYPASSABLE]"`
- `Toggle bypass on all monitoring FX whose names containin "[BYPASSABLE]"`
- `Unbypass all monitoring FX whose names contain "[BYPASSABLE]"`

These actions operate on the monitoring FX chain *only*, and only bypass/unbypass FX
that contain `[BYPASSABLE]` somewhere in their name. To rename a monitoring FX, open the monitoring FX chain, then `Right Click -> Rename FX instance` to rename your FX).

#### SWS Cycle Action preset
Because these scripts are handier with a toggleable SWS cycle action (requires [SWS](https://sws-extension.org/index.php)), I've included 
a preconfigured cycle action in the `Cycle Action/simong_CycleAction_Toggle (bypass and unbypass) monitoring FX whose name contains the phrase [BYPASSABLE].ini` preset file.

Simply [download the file](https://github.com/DefaultSimon/simong_reaper-scripts/blob/master/Cycle%20Actions/simong_CycleAction_Toggle%20(bypass%20and%20unbypass)%20monitoring%20FX%20whose%20name%20contains%20the%20phrase%20%5BBYPASSABLE%5D.ini),
then go to `Extensions -> Cycle Action editor... -> Import/export -> Import in section 'Main'...`, select the file, then click `Apply`.

