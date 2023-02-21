<h1 align="center">
    Simon Goričar's <a href="https://www.reaper.fm/">Reaper</a> Scripts
</h1>

## 1. Installation
You can use this repository via [ReaPack](https://reapack.com) by adding the following 
repository:
```
https://github.com/DefaultSimon/simong_reaper-scripts/raw/master/index.xml
```


## 2. Contents

### 2.1. `Monitoring FX Bypass scripts (based on FX names containing "[BYPASSABLE]")`

<div align="center">
    <img src="https://raw.githubusercontent.com/DefaultSimon/simong_reaper-scripts/master/assets/demo-gifs/simong_bypassing-all-monitoring-fx-whose-names-contain-[BYPASSABLE]_demo.gif" width="90%">
    <h6 align="center"><i>Notice how the monitoring FX gets (un)bypassed.</i></h6>
</div>
</br>


This package contains the following three actions:
- `Bypass all monitoring FX whose names contain "[BYPASSABLE]"`
- `Toggle bypass on all monitoring FX whose names containin "[BYPASSABLE]"`
- `Unbypass all monitoring FX whose names contain "[BYPASSABLE]"`

These actions operate on the monitoring FX chain *only*, and only bypass/unbypass FX
that contain `[BYPASSABLE]` somewhere in their name. To rename a monitoring FX, open the monitoring FX chain, then `Right Click -> Rename FX instance` to rename your FX).

<details>
<summary><i>SWS Cycle Action preset</i> for this package</summary>

Because these scripts are handier with a toggleable SWS cycle action (requires [SWS](https://sws-extension.org/index.php)), I've included 
a preconfigured cycle action in the `Cycle Action/simong_CycleAction_Toggle (bypass and unbypass) monitoring FX whose name contains the phrase [BYPASSABLE].ini` preset file.

Simply [download the file](https://github.com/DefaultSimon/simong_reaper-scripts/blob/master/Cycle%20Actions/simong_CycleAction_Toggle%20(bypass%20and%20unbypass)%20monitoring%20FX%20whose%20name%20contains%20the%20phrase%20%5BBYPASSABLE%5D.ini),
then go to `Extensions -> Cycle Action editor... -> Import/export -> Import in section 'Main'...`, select the file, then click `Apply`.

</details>

---


### 2.2. `Move selected media items onto child track whose name contains "[STEMS]"`

<div align="center">
    <img src="https://raw.githubusercontent.com/DefaultSimon/simong_reaper-scripts/master/assets/demo-gifs/simong_move-selected-items-onto-child-track_named_[stems]_demo.gif" width="90%">
    <h6 align="center"><i>In this demo, the target "stems" track is directly below the original track, but it can be any direct descendant.</i></h6>
</div>
</br>


This script moves the selected media items from the track they are on to the child "stems" track. It finds that track by looking at the track's 
direct children and finding a track whose name contains the phrase "[STEMS]".

If no "[STEMS]"-matching track is found or if no media items are selected, this script does nothing.

#### Why / Workflow
- I record a loop (or part of it),
- I now have a selected media item with what I just recorded 
- I use this action to push the just-recorded material into the child "stems" track that, importantly, still sends to the parent 
  (so I can still hear what I recorded on previous loops), 
- I'll now record a new item onto the now-empty track,
- At the end of the loop, I'll repeat the process, pushing the newly-recorded item down onto the "stems" track, effectively adding one more layer to the composition (and so on and so on).

This makes it easier to separate multiple overdubed layers of your material into separate items and name/sort/mute/... them accordingly.

#### Quirks
- Due to how items are moved, if not all of the selected media items are on the same track, the script *might* work sometimes, but it will pick a stems child track from the first selected media item. Consider this... undefined behaviour.

---


### 2.3. `Create new empty MIDI track at the same position as the selected media item`

<div align="center">
    <img src="https://raw.githubusercontent.com/DefaultSimon/simong_reaper-scripts/master/assets/demo-gifs/simong_create-new-empty-midi-track-at-the-same-position-as-the-selected-item_demo.gif" width="90%">
</div>
</br>


This script creates a new empty MIDI track at the same position (and of the same length) as the currently-selected media item. Additionally, it unselects the original media item and selects the newly created item.


</br>
</br>

---


## 3. Development Notes

#### 3.1 Semantic versioning
I try to adhere to the [semantic versioning rules](https://semver.org/#semantic-versioning-200) if at all possible.

#### 3.2 ReaScript's default `package.path`
On the default Windows installation, the default `package.path` upon launching a Lua script in Reaper is (line breaks mine, actualy value is all in one line):
```lua
C:\Program Files\REAPER (x64)\lua\?.lua;
C:\Program Files\REAPER (x64)\lua\?\init.lua;
C:\Program Files\REAPER (x64)\?.lua;
C:\Program Files\REAPER (x64)\?\init.lua;
C:\Program Files\REAPER (x64)\..\share\lua\5.3\?.lua;
C:\Program Files\REAPER (x64)\..\share\lua\5.3\?\init.lua;
.\?.lua;
.\?\init.lua
```

Most of these paths don't seem to exist (at least on my Windows machine), so the only useful parts seem to be: `.\?.lua;.\?\init.lua`.
Minor information; useful basically only for the fact that you can import adjacent scripts in the same directory without modifying the path.
